class ProductController < ApplicationController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete]

  add_breadcrumb 'Products', :product_list_path

  def list
    @products = Product.where(status: true).order('created_at desc')
    @product_pendings = Approval.where(table: 'PRODUCT').where(row_id: nil)
  end

  def new
    @product = Product.new
    add_breadcrumb 'New'
  end

  def create

    # check duplicate product code at Live table
    if Product.exists?(code: params[:product]['code'])
      flash.now[:error] = 'The Product Code already exists. It has to be unique'
      # redirect_to product_new_path
      @product = Product.new(product_params)
      render :new
      return
    end

    # check duplicate product code at cache table
    approval = Approval.where(table: 'PRODUCT')
    unless approval.blank?
      approval.each do |cache|
        if params[:product]['code'] == JSON.parse(cache.content)['code']
          flash.now[:error] = 'Product code alredy exists in Cache Table. It has to be unique'
          # redirect_to client_api_new_path
          @product = Product.new(product_params)
          render :new
          return
        end
      end
    end

    # check for spaces
    if params[:product]['code'].strip.match?(/\s/)
      flash.now[:error] = 'The Product Code cannot have empty spaces.'
      # redirect_to product_new_path
      @product = Product.new(product_params)
      render :new
      return
    end

    # create cache data
    custom_product_params = product_params
    custom_product_params[:activation_status] = product_params[:activation_status].blank? ? 'false' : product_params[:activation_status]
    Approval.create(table: 'PRODUCT', content:  custom_product_params.to_json, user: current_user.id)

    flash[:success] = 'Success create new Product'
    redirect_to product_list_path
  end

  def edit_pending
    @product = Product.new

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to product_list_path
      return
    end

    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Product is yet to be approved. What would you want to do? <a href='/product/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/product/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    @product_pending = JSON.parse(@approval.content)
    add_breadcrumb @product_pending['name']
  end

  def update_pending

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to product_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    # check duplicate product code at Live table
    if Product.exists?(code: params[:product]['code'])
      flash.now[:error] = 'The Product Code already exists. It has to be unique'
      # redirect_to product_new_path
      edit_pending
      @product = Product.new(product_params)
      render :edit_pending
      return
    end

    # check duplicate product code at cache table
    approvals = Approval.where(table: 'PRODUCT')
    unless approvals.blank?
      approvals.each do |cache|
        if params[:product]['code'] != approval.parse_content['code'] && params[:product]['code'] == JSON.parse(cache.content)['code']
          flash.now[:error] = 'Product code alredy exists in Cache Table. It has to be unique'
          # redirect_to client_api_new_path
          edit_pending
          @product = Product.new(product_params)
          render :edit_pending
          return
        end
      end
    end

    # check for spaces
    if params[:product]['code'].strip.match?(/\s/)
      flash.now[:error] = 'The Product Code cannot have empty spaces.'
      # redirect_to product_new_path
      edit_pending
      @product = Product.new(product_params)
      render :edit_pending
      return
    end

    custom_product_params = product_params
    custom_product_params[:activation_status] = product_params[:activation_status].blank? ? JSON.parse(approval.content)['activation_status'] : product_params[:activation_status]

    approval.update(content: custom_product_params.to_json, user: current_user.id)
    redirect_to "/product/edit_pending/#{approval.id}"
  end

  def edit
    @product = Product.find(params[:id])
    approval = Approval.where(table: 'PRODUCT').where(row_id: @product.id)
    @is_pending = false
    if approval.any?
      flash.now[:alert] = "This product is yet to be approved. What would you want to do? <a href='/product/approve/#{@product.id}'><strong>APPROVE</strong></a> | <a href='/product/reject/#{@product.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
      @product_pending = JSON.parse(approval.first.content)
      @is_pending = true
    end
    add_breadcrumb @product.name
  end

  def update
    product = Product.find(params[:id])

    unless product.status
      redirect_to product_list_path
      return
    end

    # check duplicate product code at Live table
    if product.code != params[:product]['code'] && Product.exists?(code: params[:product]['code'])
      flash.now[:error] = 'The Product Code already exists. It has to be unique'
      # redirect_to "/product/edit/#{product.id}"
      edit
      render :edit
      return
    end

    # check duplicate product code at cache table
    approvals = Approval.where(table: 'PRODUCT')
    unless approvals.blank?
      approvals.each do |cache|

        unless cache.row_id == product.id
          if params[:product]['code'] == JSON.parse(cache.content)['code']
            flash.now[:error] = 'Product code alredy exists in Cache Table. It has to be unique'
            # redirect_to "/product/edit/#{product.id}"
            edit
            render :edit
            return
          end
        end

      end
    end

    # check for spaces
    if params[:product]['code'].strip.match?(/\s/)
      flash.now[:error] = 'The Product Code cannot have empty spaces.'
      # redirect_to "/product/edit/#{product.id}"
      edit
      render :edit
      return
    end

    approval = Approval.where(table: 'PRODUCT').where(row_id: product.id)

    custom_product_params = product_params
    custom_product_params[:activation_status] = product_params[:activation_status].blank? ? product.activation_status.to_s : product_params[:activation_status]

    if approval.any?
      approval.first.update(content: custom_product_params.to_json, user: current_user.id)
    else
      Approval.create(
                  table: 'PRODUCT',
                  row_id: product.id,
                  content: product_params.to_json,
                  user: current_user.id
      )
    end

    flash[:success] = 'Save changes'
    redirect_to "/product/edit/#{product.id}"
  end

  def approve
    product = Product.find(params[:id])

    unless product.status
      redirect_to product_list_path
      return
    end

    approval = Approval.where(table:'PRODUCT').find_by_row_id(product.id)
    product.update(JSON.parse(approval.content))
    unless product.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Product",  product.name)
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Product",  product.name)
      end
      approval.destroy

      flash[:success] = 'Save changes product is approved.'
    end

    redirect_to "/product/edit/#{product.id}"
  end

  def approve_create

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to product_list_path
      return
    end

    approval = Approval.find(params[:approval_id])
    product = Product.create(JSON.parse(approval.content))

    unless product.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/product/edit_pending/#{approval.id}"
      return
    end


    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Product")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Product")
    end
    approval.destroy

    flash[:success] = 'Create new Product is approved.'
    redirect_to "/product/edit/#{product.id}"

  end

  def reject
    product = Product.find(params[:id])

    unless product.status
      redirect_to product_list_path
      return
    end

    approval = Approval.where(table:'PRODUCT').find_by_row_id(product.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Product",  product.name)
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Product",  product.name)
    end
    approval.destroy
    flash[:success] = 'Save changes Product is rejected.'
    redirect_to "/product/edit/#{product.id}"
  end

  def reject_delete

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to product_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Product")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Product")
    end
    approval.destroy
    flash[:success] = 'New pending Product is rejected.'
    redirect_to product_list_path
  end

  def delete
    product = Product.find(params[:id])
    product.update(status: false)
    flash[:success] = 'Success deleted product'
    redirect_to product_list_path
  end

  private

  def product_params
    params.require(:product).permit(:name, :code, :activation_status)
  end

end
