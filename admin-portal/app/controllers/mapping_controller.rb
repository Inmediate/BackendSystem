class MappingController < ApplicationController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete]

  add_breadcrumb 'Mapping', :mapping_list_path

  def list
    @mappings = Mapping.where(status: true).order('created_at desc')
    @mapping_pendings = Approval.where(table: 'MAPPING').where(row_id: nil)
  end

  def new
    @mapping = Mapping.new
    add_breadcrumb 'New'
  end

  def create
    Approval.create(table: 'MAPPING', content:  mapping_params.to_json, user: current_user.id)
    flash[:success] = 'Success create new Mapping'
    redirect_to mapping_list_path
  end

  def edit_pending

    @mapping = Mapping.new
    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Mapping is yet to be approved. What would you want to do? <a href='/mapping/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/mapping/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    # api cache is not exist
    if @approval.nil?
      redirect_to mapping_list_path
      return
    end

    @mapping_pending = JSON.parse(@approval.content)
    add_breadcrumb @mapping_pending['name']

  end

  def update_pending
    approval = Approval.find(params[:approval_id])
    approval.update(content: mapping_params.to_json, user: current_user.id)

    flash[:success] = 'Save changes Mapping'
    redirect_to "/mapping/edit_pending/#{approval.id}"
  end

  def edit
    @mapping = Mapping.find(params[:id])
    approval = Approval.where(table: 'MAPPING').where(row_id: @mapping.id)
    @is_pending = false
    if approval.any?
      flash.now[:alert] = "This Mapping is yet to be approved. What would you want to do? <a href='/mapping/approve/#{@mapping.id}'><strong>APPROVE</strong></a> | <a href='/mapping/reject/#{@mapping.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
      @mapping_pendings = JSON.parse(approval.first.content)
      @is_pending = true
    end
    add_breadcrumb @mapping.name
  end

  def update
    mapping = Mapping.find(params[:id])

    # get approval
    approval = Approval.where(table: 'MAPPING').where(row_id: mapping.id)

    if approval.any?
      approval.first.update(content: mapping_params.to_json, user: current_user.id)
    else
      Approval.create(
        table: 'MAPPING',
        row_id: mapping.id,
        content: mapping_params.to_json,
        user: current_user.id
      )
    end

    flash[:success] = 'Save changes Mapping'
    redirect_to "/mapping/edit/#{mapping.id}"
  end

  def delete
    mapping = Mapping.find(params[:id])
    mapping.update(status: false)
    flash[:success] = 'Deleted Mapping'
    redirect_to mapping_list_path
  end

  def approve
    mapping = Mapping.find(params[:id])
    approval = Approval.where(table:'MAPPING').find_by_row_id(mapping.id)
    mapping.update(JSON.parse(approval.content))

    unless mapping.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Mapping List",  mapping.name)
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Mapping List",  mapping.name)
      end
      approval.destroy
      flash[:success] = 'Save changes Mapping is approved.'
    end

    redirect_to "/mapping/edit/#{mapping.id}"
  end

  def approve_create
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to mapping_list_path
      return
    end

    mapping = Mapping.create(JSON.parse(approval.content))

    unless mapping.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/mapping/edit_pending/#{approval.id}"
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Mapping List")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Mapping List")
    end
    approval.destroy

    flash[:success] = 'Create new Mapping is approved.'
    redirect_to "/mapping/edit/#{mapping.id}"
  end

  def reject
    mapping = Mapping.find(params[:id])
    approval = Approval.where(table:'MAPPING').find_by_row_id(mapping.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Mapping List",  mapping.name)
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Mapping List",  mapping.name)
    end
    approval.destroy
    flash[:success] = 'Save changes Mapping is rejected.'
    redirect_to "/mapping/edit/#{mapping.id}"
  end

  def reject_delete

    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to mapping_list_path
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Mapping List")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Mapping List")
    end
    approval.destroy

    flash[:success] = 'Pending Mapping is rejected.'
    redirect_to mapping_list_path
  end

  private

  def mapping_params
    params.require(:mapping).permit(:name, :list)
  end
end
