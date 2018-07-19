class ClientApiController < ApplicationController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete delete_pending]

  add_breadcrumb 'Client APIs', :client_api_list_path

  def list
    @apis = ClientApi.where(status: true).order('created_at desc')
    @api_pendings = Approval.where(table: 'CLIENT_API').where(row_id: nil)
  end

  def new
    @api = ClientApi.new
    add_breadcrumb 'New'
  end

  def create

    # check for duplicate path at Live table
    if ClientApi.where(status: true).exists?(path: params[:client_api]['path'])
      flash.now[:error] = 'Path Name already exists. It has to be unique'
      # redirect_to client_api_new_path
      @api = ClientApi.new(client_api_params)
      render :new
      return
    end

    # check for duplicate path at Cache table
    approval = Approval.where(table: 'CLIENT_API')
    unless approval.blank?
      approval.each do |cache|
       if params[:client_api]['path'] == JSON.parse(cache.content)['path']
         flash.now[:error] = 'Path Name alredy exists in Cache Table. It has to be unique'
         # redirect_to client_api_new_path
         @api = ClientApi.new(client_api_params)
         render :new
         return
       end
      end
    end

    # check for payload key_name duplicates
    unless params[:client_api]['payloads'].nil?
      unless params[:client_api]['payloads'].count == params[:client_api]['payloads'].uniq{ |s| s['key_name'] }.count
        flash.now[:error] = 'Payload Key_Name must be unique. Please try again.'
        # redirect_to client_api_new_path
        @api = ClientApi.new(client_api_params)
        render :new
        return
      end
    end

    # create payload string
    payloads = []
    payloads = params[:client_api]['payloads'] unless params[:client_api]['payloads'].nil?
    custom_client_api_params = client_api_params
    custom_client_api_params[:payloads] = payloads.to_json
    custom_client_api_params[:activation_status] = client_api_params[:activation_status].blank? ? 'false' : client_api_params[:activation_status]
    Approval.create(
        table: 'CLIENT_API',
        content:  custom_client_api_params.to_json,
        user: current_user.id
    )

    flash[:success] = 'Success create new Client API'
    redirect_to client_api_list_path

  end

  def edit_pending

    unless Approval.where(id: params[:approval_id]).any?
      redirect_to client_api_list_path
      return
    end

    @api = ClientApi.new
    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Client API is yet to be approved. What would you want to do? <a href='/client/api/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/client/api/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    # api cache is not exist
    if @approval.nil?
      redirect_to client_api_list_path
      return
    end

    @api_pending = JSON.parse(@approval.content)
    @payload_pending = JSON.parse(@api_pending['payloads'])

    add_breadcrumb @api_pending['name']

  end

  def update_pending

    unless Approval.where(id: params[:approval_id]).any?
      redirect_to client_api_list_path
      return
    end

    approval = Approval.find(params[:approval_id])


    # check for duplicate path at Live table
    if ClientApi.where(status: true).exists?(path: params[:client_api]['path'])
      flash.now[:error] = 'Path Name already exists. It has to be unique'
      # redirect_to "/client/api/edit_pending/#{approval.id}"
      edit_pending
      @api_pending = ClientApi.new(client_api_params)
      render :edit_pending
      return
    end

    # check for duplicate path at Cache table
    approvals = Approval.where(table: 'CLIENT_API')
    unless approvals.blank?
      approvals.each do |cache|
        if params[:client_api]['path'] != approval.parse_content['path'] && params[:client_api]['path'] == JSON.parse(cache.content)['path']
          flash.now[:error] = 'Path Name already exists in Cache Table. It has to be unique'
          # redirect_to "/client/api/edit_pending/#{approval.id}"
          edit_pending
          @api_pending = ClientApi.new(client_api_params)
          render :edit_pending
          return
        end
      end
    end

    # check for payload key_name duplicates
    unless params[:client_api]['payloads'].nil?
      unless params[:client_api]['payloads'].count == params[:client_api]['payloads'].uniq{ |s| s['key_name'] }.count
        flash.now[:error] = 'Payload Key Name must be unique. Please try again.'
        # redirect_to "/client/api/edit_pending/#{approval.id}"
        edit_pending
        @api_pending = ClientApi.new(client_api_params)
        render :edit_pending
        return
      end
    end

    if approval.nil?
      redirect_to client_api_list_path
      return
    end

    payloads = []
    payloads = params[:client_api]['payloads'] unless params[:client_api]['payloads'].blank?
    custom_client_api_params = client_api_params
    custom_client_api_params[:payloads] = payloads.to_json
    custom_client_api_params[:activation_status] = client_api_params[:activation_status].blank? ? JSON.parse(approval.content)['activation_status'] : client_api_params[:activation_status]
    approval.update(content: custom_client_api_params.to_json, user: current_user.id)

    flash[:success] = 'Save changes Client API'
    redirect_to "/client/api/edit_pending/#{approval.id}"
  end

  def delete_pending

    unless Approval.where(id: params[:approval_id]).any?
      redirect_to client_api_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to client_api_list_path
      return
    end

    approval.destroy
    redirect_to client_api_list_path
  end

  def edit

    unless ClientApi.where(id: params[:id]).any?
      redirect_to client_api_list_path
      return
    end

    @api = ClientApi.find(params[:id])
    approval = Approval.where(table: 'CLIENT_API').where(row_id: @api.id)
    @is_pending = false
    if approval.any?
      flash.now[:alert] = "This Client API is yet to be approved. What would you want to do? <a href='/client/api/approve/#{@api.id}'><strong>APPROVE</strong></a> | <a href='/client/api/reject/#{@api.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
      @api_pending = JSON.parse(approval.first.content)
      @is_pending = true
      @is_authorization_att = @api_pending['authorization'] == "1" ? true : false
      @is_validation_att = @api_pending['validation'] == "1" ? true : false
    end

    @api_payload = unless @api.payloads.blank?
                     JSON.parse(@api.payloads)
                   else
                     nil
                   end

    @payload_sample = unless @api_payload.blank?
                        result = {}
                        @api_payload.each do |payload|
                          next unless payload['parent_array'].blank?
                          result["#{payload['key_name']}"]  = if payload['is_array'] == 'true'
                                                                 if @api_payload.any? {|s| s['parent_array'] == payload['key_name']}
                                                                   child_hash = {}
                                                                   child_array = []
                                                                   @api_payload.each do |child|
                                                                     next unless child['parent_array'] == payload['key_name']
                                                                     child_hash["#{child['key_name']}"] = 'value'
                                                                   end
                                                                   child_array << child_hash
                                                                   child_array
                                                                 else
                                                                   []
                                                                 end
                                                               else
                                                                 'value'
                                                               end
                        end
                        result
                      else
                        nil
                      end

    add_breadcrumb @api.name

  end

  def update

    api = ClientApi.find(params[:id])

    unless api.status
      redirect_to client_api_list_path
      return
    end

    # check duplicat path at Live table
    if api.path != params[:client_api]['path'] && ClientApi.where(status: true).exists?(path: params[:client_api]['path'])
      flash.now[:error] = 'Path Name already exists. It has to be unique'
      # redirect_to "/client/api/edit/#{api.id}"
      edit
      @is_authorization_att= params[:client_api]['authorization'] == "1" ? true : false
      @is_validation_att= params[:client_api]['validation'] == "1" ? true : false
      render :edit
      return
    end

    # check for duplicate path at Cache table
    approvals = Approval.where(table: 'CLIENT_API')
    unless approvals.blank?
      approvals.each do |cache|
        unless cache.row_id == api.id
          if params[:client_api]['path'] == JSON.parse(cache.content)['path']
            flash.now[:error] = 'Path Name already exists in Cache Table. It has to be unique'
            edit
            @is_authorization_att= params[:client_api]['authorization'] == "1" ? true : false
            @is_validation_att= params[:client_api]['validation'] == "1" ? true : false
            render :edit
            return
          end
        end
      end
    end

    # check for payload key_name duplicates
    unless params[:client_api]['payloads'].nil?
      unless params[:client_api]['payloads'].count == params[:client_api]['payloads'].uniq{ |s| s['key_name'] }.count
        flash.now[:error] = 'Payload Key Name must be unique. Please try again.'
        # redirect_to "/client/api/edit_pending/#{approval.id}"
        edit
        @is_authorization_att= params[:client_api]['authorization'] == "1" ? true : false
        @is_validation_att= params[:client_api]['validation'] == "1" ? true : false
        render :edit
        return
      end
    end

    # create payload
    payloads = []
    payloads = params[:client_api]['payloads'] unless params[:client_api]['payloads'].blank?
    custom_client_api_params = client_api_params
    custom_client_api_params[:payloads] = payloads.to_json
    custom_client_api_params[:activation_status] = client_api_params[:activation_status].blank? ? api.activation_status.to_s : client_api_params[:activation_status]

    # get approval
    approval = Approval.where(table: 'CLIENT_API').where(row_id: api.id)

    if approval.any?
      approval.first.update(
          content:  custom_client_api_params.to_json,
          user: current_user.id
      )
    else
      Approval.create(
          table: 'CLIENT_API',
          row_id: api.id,
          content:  custom_client_api_params.to_json,
          user: current_user.id
      )
    end

    flash[:success] = 'Save changes pending Client API'
    redirect_to "/client/api/edit/#{api.id}"
  end

  def approve
    api = ClientApi.find(params[:id])

    unless api.status
      redirect_to client_api_list_path
      return
    end

    approval = Approval.where(table:'CLIENT_API').find_by_row_id(api.id)
    api.update(JSON.parse(approval.content))
    unless api.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Client API",  api.name)
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Client API",  api.name)
      end
      approval.delete
      flash[:success] = 'Save changes Client API is approved.'
    end

    redirect_to "/client/api/edit/#{api.id}"
  end

  def approve_create

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_api_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    api = ClientApi.create(JSON.parse(approval.content))

    unless api.status
      redirect_to client_api_list_path
      return
    end

    unless api.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/client/api/edit_pending/#{approval.id}"
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Client API")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Client API")
    end
    approval.destroy

    flash[:success] = 'Create new Client API is approved.'
    redirect_to "/client/api/edit/#{api.id}"
  end

  def reject
    api = ClientApi.find(params[:id])
    approval = Approval.where(table:'CLIENT_API').find_by_row_id(api.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Client API",  api.name)
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Client API",  api.name)
    end
    approval.destroy
    flash[:success] = 'Save changes Client API is rejected.'
    redirect_to "/client/api/edit/#{api.id}"
  end

  def reject_delete
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to client_api_list_path
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Client API")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Client API")
    end
    approval.destroy
    flash[:success] = 'New pending Client API is rejected.'
    redirect_to client_api_list_path
  end

  def delete

    api = ClientApi.find(params[:id])
    Approval.where(table:'CLIENT_API').where(row_id: api.id).destroy_all
    api.update(status: false)

    unless api.save
      flash[:error] = 'Failed deleting Client API'
    else
      flash[:success] = 'Deleted Client API'
    end

    redirect_to client_api_list_path
  end

  private

  def client_api_params
    params.require(:client_api).permit(:name, :product_id, :path, :derived_from, :method, :authorization, :validation, :activation_status)
  end


end
