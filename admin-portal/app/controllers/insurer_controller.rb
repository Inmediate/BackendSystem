class InsurerController < ApplicationController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete]
  before_action

  add_breadcrumb 'Insurer', :insurer_list_path

  def list
    @insurers = Insurer.where(status: true).order('created_at asc')
    @insurer_pendings = Approval.where(table: 'INSURER').where(row_id: nil)
  end

  def new
    @insurer = Insurer.new
    add_breadcrumb 'New'
  end

  def create
    puts "asdasdasdasdasdlansdlkasndlasndlaskdanlsndaskldnalsdnalsdsak"
    # check duplicate company_code at Live Table
    if Insurer.exists?(company_code: params[:insurer]['company_code'])
      flash.now[:error] = 'Company Code already exists. It has to be unique'
      @insurer = Insurer.new(insurer_params.except(:products))
      render :new
      return
    end

    # check duplicate company_code at Cache Table
    approval = Approval.where(table: 'INSURER')
    unless approval.blank?
      approval.each do |cache|
        if params[:insurer]['company_code'] == JSON.parse(cache.content)['company_code']
          flash.now[:error] = 'Company Code alredy exists in Cache Table. It has to be unique'
          @insurer = Insurer.new(insurer_params.except(:products))
          render "/insurer/new"
          return
        end
      end
    end

    # get product array
    products = []
    products = params[:insurer]['products'] unless params[:insurer]['products'].nil?
    custom_insurer_params = insurer_params.except(:products)
    custom_insurer_params[:products] = products.to_json
    custom_insurer_params[:activation_status] = insurer_params[:activation_status].blank? ? 'false' : insurer_params[:activation_status]

    Approval.create(
        table: 'INSURER',
        content:  custom_insurer_params.to_json,
        user: current_user.id
    )

    flash[:success] = 'Successed create Insurer'
    redirect_to insurer_list_path
  end

  def edit_pending
    @insurer = Insurer.new
    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Insurer is yet to be approved. What would you want to do? <a href='/insurer/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/insurer/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    # api cache is not exist
    if @approval.nil?
      redirect_to insurer_list_path
      return
    end

    @insurer_pending = JSON.parse(@approval.content)
    @product_pending = JSON.parse(@insurer_pending['products'])

    add_breadcrumb @insurer_pending['company_name']

  end

  def update_pending
    approval = Approval.find(params[:approval_id])

    # check duplicate company_code at Live Table
    if Insurer.exists?(company_code: params[:insurer]['company_code'])
      flash.now[:error] = 'Company Code already exists. It has to be unique'
      # redirect_to insurer_new_path
      edit_pending
      @insurer = Insurer.new(insurer_params.except(:products))
      render :edit_pending
      return
    end

    # check duplicate company_code at Cache Table
    approvals = Approval.where(table: 'INSURER')
    unless approvals.blank?
      approvals.each do |cache|
        if params[:insurer]['company_code'] != approval.parse_content['company_code'] && params[:insurer]['company_code'] == JSON.parse(cache.content)['company_code']
          flash.now[:error] = 'Company Code alredy exists in Cache Table. It has to be unique'
          # redirect_to insurer_new_path
          edit_pending
          @insurer = Insurer.new(insurer_params.except(:products))
          render :edit_pending
          return
        end
      end
    end

    if approval.nil?
      redirect_to insurer_list_path
      return
    end

    products = []
    products = params[:insurer]['products'] unless params[:insurer]['products'].nil?
    custom_insurer_params = insurer_params.except(:products)
    custom_insurer_params[:products] = products.to_json
    custom_insurer_params[:activation_status] = insurer_params[:activation_status].blank? ? JSON.parse(approval.content)['activation_status'] : insurer_params[:activation_status]
    approval.update(content: custom_insurer_params.to_json, user: current_user.id)

    flash[:success] = 'Save changes Insurer'
    redirect_to "/insurer/edit_pending/#{approval.id}"

  end

  def edit

    respond_to do |format|
      format.json do

        insurer = Insurer.find(params[:insurer_id])
        insurer_filter = params[:type] == 'product' ? params[:product_id].to_i : nil
        auth_api_filter =  params[:type] == 'auth_api' ? true : false

        # activation_status filter
        activation = nil
        unless params[:search][:value].blank?
          if params[:search][:value].casecmp('Activated') == 0
            activation = true
          end

          if params[:search][:value].casecmp('Deactivated') == 0
            activation = false
          end
        end

        # sorting filter
        order = params['order']['0']['dir']
        sort = ''
        if params['order']['0']['column'] == '0'
          sort = 'created_at'
          if order == 'asc'
            order = 'desc'
          else
            order = 'asc'
          end
        elsif params['order']['0']['column'] == '1'
          sort = 'client_api_id'
        elsif params['order']['0']['column'] == '2'
          sort = 'cache_policy'
        elsif params['order']['0']['column'] == '3'
          sort = 'cache_timeout'
        elsif params['order']['0']['column'] == '4'
          sort = 'api_url'
        elsif params['order']['0']['column'] == '5'
          sort = 'api_method'
        elsif params['order']['0']['column'] == '6'
          sort = 'api_flavour'
        elsif params['order']['0']['column'] == '7'
          sort = 'payload_type'
        elsif params['order']['0']['column'] == '8'
          sort = 'activation_status'
        end
        # sort = if

        insurer_apis = if auth_api_filter
                         activation.nil? ? insurer.insurer_product_apis.where(status: true).where(is_authentication: true).order("#{sort} #{order}") : insurer.insurer_product_apis.where(status: true).where(is_authentication: true).where(activation_status: activation).order('created_at desc')
                        elsif !insurer_filter.nil?
                          client_api_ids = ClientApi.where(product_id: insurer_filter).map {|s| s.id}
                          activation.nil? ? insurer.insurer_product_apis.where(status: true).where(client_api_id: client_api_ids).order('created_at desc') : insurer.insurer_product_apis.where(status: true).where(client_api_id: client_api_ids).where(activation_status: activation).order('created_at desc')
                        else
                          activation.nil? ? insurer.insurer_product_apis.where(status: true).order("#{sort} #{order}") : insurer.insurer_product_apis.where(status: true).where(activation_status: activation).order("#{sort} #{order}")
                       end

        insurer_apis = params[:search][:value].blank? || !activation.nil? ? insurer_apis : InsurerProductAPIFilter.new.filter(insurer_apis, params[:search][:value])

        # insurer product api pending creation
        insurer_api_pendings = []
        approvals = params[:search][:value].blank? || !activation.nil?  ? Approval.where(table: 'INSURER_PRODUCT_API').where(row_id: nil) : Approval.where(table: 'INSURER_PRODUCT_API').where(row_id: nil).where("content like ?", "%#{params[:search][:value]}%")
        approvals.each do |pending|

          unless activation.nil?
            if activation
              next if JSON.parse(pending.content)['activation_status'] == 'false'
            elsif !activation
              next if JSON.parse(pending.content)['activation_status'] == 'true'
            end
          end

          if JSON.parse(pending.content)['insurer_id'].to_i == insurer.id
            if auth_api_filter
              next unless JSON.parse(pending.content)['is_authentication'] == '1'
              insurer_api_pendings << pending
            elsif !insurer_filter.nil?
              next unless client_api_ids.include? (JSON.parse(pending.content)['client_api_id'].to_i)
              insurer_api_pendings << pending
            else
              insurer_api_pendings << pending
            end
          end
        end

        insurer_apis_paged = insurer_apis.page(1).per(params[:length].to_i).padding(params[:start].to_i)

        result = {}

        result[:draw] = params[:draw].to_i
        result[:recordsTotal] = insurer_apis.count + insurer_api_pendings.count
        result[:recordsFiltered] = result[:recordsTotal]

        insurer_apis_array = []

        if params[:start].to_i == 0
          insurer_api_pendings.each_with_index do |api, index|
            api_array = []

            api_name = api.insurer_product_api_is_authetication ? "Authentication API" : ClientApi.find(api.parse_content['client_api_id']).name

            api_array << index + 1
            api_array << "<i class='fas fa-exclamation-circle' style='color: red'></i> #{api_name}".html_safe
            api_array << api.parse_content['cache_policy']
            api_array << api.parse_content['cache_timeout']
            api_array << api.parse_content['api_url']
            api_array << api.parse_content['api_method']
            api_array << api.parse_content['api_flavour']
            api_array << api.parse_content['payload_type']
            api_array << "#{api.parse_content['activation_status'] == 'true' ? 'Activated' : 'Deactivated'}"
            api_array << api.id
            api_array << false
            api_array << "edit_pending"
            insurer_apis_array << api_array
          end
        end

        insurer_apis_paged.each_with_index do |api, index|
          api_array = []

          api_name = api.is_authentication ? "Authentication API" : api.client_api.name
          pending = Approval.where(table: 'INSURER_PRODUCT_API').where(row_id: api.id).any? ? true : false
          api_name = pending ? "<i class='fas fa-exclamation-circle' style='color: red'></i> #{api_name}".html_safe : api_name

          api_array << insurer_api_pendings.count + index + 1
          api_array << api_name
          api_array << api.cache_policy
          api_array << api.cache_timeout
          api_array << api.api_url
          api_array << api.api_method
          api_array << api.api_flavour
          api_array << api.payload_type
          api_array << "#{api.activation_status ? 'Activated' : 'Deactivated'}"
          api_array << api.id
          api_array << pending
          api_array << "edit"
          insurer_apis_array << api_array
        end

        result[:data] = insurer_apis_array

        puts "result #{result.to_json}"

        render json: result.to_json

      end
      format.html do

        @insurer = Insurer.find(params[:id])

        add_breadcrumb @insurer.company_name

        @current_insurer = Insurer.find(params[:id])

        # support product
        @insurer_products = @insurer.products

        approval = Approval.where(table: 'INSURER').where(row_id: @insurer.id)
        @is_pending = false
        if approval.any?
          flash.now[:alert] = "This Insurer is yet to be approved. What would you want to do? <a href='/insurer/approve/#{@insurer.id}'><strong>APPROVE</strong></a> | <a href='/insurer/reject/#{@insurer.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
          @insurer_pending = JSON.parse(approval.first.content)
          @is_pending = true
        end

        # insurer mapping
        @insurer_mapping = []
        unless @insurer.mapping.blank?
          @insurer_mapping = JSON.parse(@insurer.mapping)
        end



      end
    end

  end

  def current_insurer
    @current_insurer
  end

  def update
    insurer = Insurer.find(params[:id])

    # check duplicate for company Code at Live Table
    if insurer.company_code != params[:insurer]['company_code'] && Insurer.exists?(company_code: params[:insurer]['company_code'])
      flash.now[:error] = 'The Company Code already exists. It has to be unique'
      # redirect_to "/insurer/edit/#{insurer.id}"
      edit
      render :edit
      return
    end

    # check duplicate company_code at Cache Table
    approvals = Approval.where(table: 'INSURER')
    unless approvals.blank?
      approvals.each do |cache|
        unless cache.row_id == insurer.id
          if params[:insurer]['company_code'] == JSON.parse(cache.content)['company_code']
            flash.now[:error] = 'Company Code alredy exists in Cache Table. It has to be unique'
            # redirect_to insurer_new_path
            edit
            render :edit
            return
          end
        end
      end
    end

    # get approval
    approval = Approval.where(table: 'INSURER').where(row_id: insurer.id)

    products = []
    products = params[:insurer]['products'] unless params[:insurer]['products'].nil?
    custom_insurer_params = insurer_params.except(:products)
    custom_insurer_params[:products] = products.to_json
    custom_insurer_params[:activation_status] = insurer_params[:activation_status].blank? ? insurer.activation_status.to_s : insurer_params[:activation_status]


    if approval.any?
      approval.first.update(content: custom_insurer_params.to_json, user: current_user.id)
    else
      Approval.create(
          table: 'INSURER',
          row_id: insurer.id,
          content: custom_insurer_params.to_json,
          user: current_user.id
      )
    end


    flash[:success] = 'Save changes Insurer'
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def delete
    insurer = Insurer.find(params[:id])
    approval = Approval.where(table:'INSURER').where(row_id: insurer.id).destroy_all
    insurer.update(status: false)
    flash[:success] = 'Deleted Insurer'
    redirect_to insurer_list_path
  end

  def approve
    insurer = Insurer.find(params[:id])
    approval = Approval.where(table:'INSURER').find_by_row_id(insurer.id)
    insurer.update(JSON.parse(approval.content).except('products'))
    unless insurer.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # reset Insurer Product association
      InsurerProduct.where(insurer_id: insurer.id).destroy_all
      products = JSON.parse(JSON.parse(approval.content).fetch('products'))
      unless products.blank?
        products.each do |product|
          insurer.products << Product.find(product)
        end
      end

      insurer.save

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Insurer",  insurer.company_name)
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Insurer",  insurer.company_name)
      end
      approval.destroy
      flash[:success] = 'Save changes Insurer is approved.'

    end

    redirect_to "/insurer/edit/#{insurer.id}"

  end

  def approve_create
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to insurer_list_path
      return
    end

    insurer = Insurer.create(JSON.parse(approval.content).except('products'))
    products = JSON.parse(JSON.parse(approval.content).fetch('products'))
    unless products.blank?
      products.each do |product|
        insurer.products << Product.find(product)
      end
    end

    insurer.save

    unless insurer.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/insurer/edit_pending/#{approval.id}"
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Insurer")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Insurer")
    end
    approval.destroy

    flash[:success] = 'Create new Insurer is approved.'
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def reject
    insurer = Insurer.find(params[:id])
    approval = Approval.where(table:'INSURER').find_by_row_id(insurer.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Insurer",  insurer.company_name)
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Insurer",  insurer.company_name)
    end
    approval.destroy
    flash[:success] = 'Save changes Insurer is rejected.'
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def reject_delete
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to insurer_list_path
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Insurer")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Insurer")
    end
    approval.destroy
    flash[:success] = 'New pending Insurer is rejected.'
    redirect_to insurer_list_path
  end

  private

  def insurer_params
    params.require(:insurer).permit(:company_name, :company_address, :company_phone, :website_url, :company_code, :contact_person_name, :contact_person_email, :contact_person_phone, :activation_status, :mapping, products: [])
  end
end
