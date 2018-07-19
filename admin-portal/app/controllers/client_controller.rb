class ClientController < ApplicationController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete]

  add_breadcrumb 'Clients', :client_list_path

  def list
    @clients = Client.where(status: true).order('created_at desc')
    @client_pendings = Approval.where(table: 'CLIENT').where(row_id: nil)
  end

  def new
    @client = Client.new
    add_breadcrumb 'New'
  end

  def create

    client_apis = params[:client]['client_apis'].blank? ? [] : params[:client]['client_apis']
    insurers = params[:client]['insurers'].blank? ? [] : params[:client]['insurers']
    custom_client_params = client_params.except(:client_apis, :insurers)
    custom_client_params[:client_code] = generate_client_code
    custom_client_params['client_api_key'] = generate_client_api_key
    custom_client_params[:client_apis] = client_apis.to_json
    custom_client_params[:insurers] = insurers.to_json
    custom_client_params[:activation_status] = client_params[:activation_status].blank? ? 'false' : client_params[:activation_status]
    Approval.create(
        table: 'CLIENT',
        content:  custom_client_params.to_json,
        user: current_user.id
    )

    flash[:success] = 'Success created new Client'
    redirect_to client_list_path

  end

  def edit_pending

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_list_path
      return
    end

    @client = Client.new
    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Client is yet to be approved. What would you want to do? <a href='/client/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/client/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    # api cache is not exist
    if @approval.nil?
      redirect_to client_list_path
      return
    end

    @client_pending = JSON.parse(@approval.content)
    @client_api_pending = JSON.parse(@client_pending['client_apis'])
    @insurer_pending = JSON.parse(@client_pending['insurers'])

    add_breadcrumb @client_pending['name']
  end

  def reset_api_key_pending

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    # get pending client api key
    hash_pending = JSON.parse(approval.content)
    hash_pending['client_api_key'] = generate_client_api_key
    approval.update(content: hash_pending.to_json, user: current_user.id)

    flash[:success] = 'Reset new Client API Key'
    redirect_to "/client/edit_pending/#{approval.id}"
  end

  def update_pending

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_list_path
      return
    end

    approval = Approval.find(params[:approval_id])

    client_apis = params[:client]['client_apis'].blank? ? [] : params[:client]['client_apis']
    insurers = params[:client]['insurers'].blank? ? [] : params[:client]['insurers']
    custom_client_params = client_params.except(:client_apis, :insurers)
    custom_client_params[:client_code] = params[:client]['client_code']
    custom_client_params[:client_apis] = client_apis.to_json
    custom_client_params[:insurers] = insurers.to_json
    custom_client_params[:activation_status] = client_params[:activation_status].blank? ? JSON.parse(approval.content)['activation_status'] : client_params[:activation_status]

    approval.update(content: custom_client_params.to_json, user: current_user.id)

    flash[:success] = 'Save changes pending Client'
    redirect_to "/client/edit_pending/#{approval.id}"
  end

  def edit

    @client = Client.find(params[:id])

    unless @client.status
      redirect_to client_list_path
      return
    end

    approval = Approval.where(table: 'CLIENT').where(row_id: @client.id)
    @is_pending = false
    if approval.any?
      flash.now[:alert] = "This Client is yet to be approved. What would you want to do? <a href='/client/approve/#{@client.id}'><strong>APPROVE</strong></a> | <a href='/client/reject/#{@client.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
      @client_pending = JSON.parse(approval.first.content)
      @is_pending = true
    end

    add_breadcrumb @client.name

  end

  def update
    client = Client.find(params[:id])

    unless client.status
      redirect_to client_list_path
      return
    end

    # get approval
    approval = Approval.where(table: 'CLIENT').where(row_id: client.id)
    # current_client_api_key = JSON.parse(approval.first.content)['client_api_key']
    client_apis = params[:client]['client_apis'].blank? ? [] : params[:client]['client_apis']
    insurers = params[:client]['insurers'].blank? ? [] : params[:client]['insurers']
    custom_client_params = client_params.except(:client_apis, :insurers)
    custom_client_params[:client_apis] = client_apis.to_json
    custom_client_params[:insurers] = insurers.to_json
    custom_client_params[:activation_status] = client_params[:activation_status].blank? ? client.activation_status.to_s : client_params[:activation_status]

    if approval.any?
      approval.first.update(content: custom_client_params.to_json, user: current_user.id)
    else
      Approval.create(
          table: 'CLIENT',
          row_id: client.id,
          content: custom_client_params.to_json,
          user: current_user.id
      )
    end

    flash[:success] = 'Save changes pending Client'
    redirect_to "/client/edit/#{client.id}"

  end

  def delete
    client = Client.find(params[:id])
    approval = Approval.where(table:'CLIENT').where(row_id: client.id).destroy_all
    client.update(status: false)
    flash[:success] = 'Success delete Client'
    redirect_to client_list_path
  end

  def approve
    client = Client.find(params[:id])

    unless client.status
      redirect_to client_list_path
      return
    end

    approval = Approval.where(table:'CLIENT').find_by_row_id(client.id)
    client.update(JSON.parse(approval.content).except('client_apis', 'insurers'))

    unless client.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # reset client client api association
      ClientApiClient.where(client_id: client.id).destroy_all
      InsurerClient.where(client_id: client.id).destroy_all

      # create clients_client_apis association
      if JSON.parse(approval.content).has_key?('client_apis')
        array_client_apis = JSON.parse(JSON.parse(approval.content).fetch('client_apis'))
        if array_client_apis.any?
          array_client_apis.each do |api|
            client.client_apis << ClientApi.find(api)
          end
        end
      end

      # create clients_insurers association
      # "{\"12\":[\"11\",\"15\"],\"13\":[\"15\"]}"
      if JSON.parse(approval.content).has_key?('insurers')
        array_products = JSON.parse(JSON.parse(approval.content).fetch('insurers'))
        puts "array products#{array_products}"
        array_products.each do |key, array|
          next if array.blank?
          array.each do |insurer|
            InsurerClient.create(insurer_id: insurer.to_i, client_id: client.id, product_id: key.to_i)
          end
        end
      end

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Client",  client.name)
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Client",  client.name)
      end
      approval.destroy
      flash[:success] = 'Save changes Client is approved.'
    end

    redirect_to "/client/edit/#{client.id}"
  end

  def approve_create

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_list_path
      return
    end

    approval = Approval.find(params[:approval_id])
    client_pending = JSON.parse(approval.content).except('client_apis', 'insurers')
    client = Client.create(client_pending)

    unless client.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/client/edit_pending/#{approval.id}"
      return
    end

    # create clients_client_apis association
    client_api_pending = JSON.parse(JSON.parse(approval.content)['client_apis'])
    unless client_api_pending.blank?
      client_api_pending.each do |api|
        client.client_apis << ClientApi.find(api)
      end
    end

    # create clients_insurers association
    # insurer_pending = JSON.parse(JSON.parse(approval.content)['insurers'])
    # unless insurer_pending.blank?
    #   insurer_pending.each do |api|
    #     client.insurers << Insurer.find(api)
    #   end
    # end

    array_products = JSON.parse(JSON.parse(approval.content).fetch('insurers'))
    unless array_products.blank?
      array_products.each do |key, array|
        next if array.blank?
        array.each do |insurer|
          InsurerClient.create(insurer_id: insurer.to_i, client_id: client.id, product_id: key.to_i)
        end
      end
    end


    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Client")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Client")
    end
    approval.destroy

    flash[:success] = 'Create new Client is approved.'
    redirect_to "/client/edit/#{client.id}"
  end

  def reject
    client = Client.find(params[:id])

    unless client.status
      redirect_to client_list_path
      return
    end

    approval = Approval.where(table:'CLIENT').find_by_row_id(client.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Client",  client.name)
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Client",  client.name)
    end
    approval.destroy
    flash[:success] = 'Save changes Client is rejected.'
    redirect_to "/client/edit/#{client.id}"
  end

  def reject_delete

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to client_list_path
      return
    end

    approval = Approval.find(params[:approval_id])
    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Client")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Client")
    end
    approval.destroy
    flash[:success] = 'New pending Client is rejected.'
    redirect_to client_list_path
  end

  def reset_api_key
    client = Client.find(params[:id])

    unless client.status
      redirect_to client_list_path
      return
    end

    approval = Approval.where(table: 'CLIENT').where(row_id: client.id)

    if approval.any?
      content_hash = JSON.parse(approval.first.content)
      content_hash['client_api_key'] = generate_client_api_key
      approval.first.update(content:  content_hash.to_json, user: current_user.id)

    else
      content_hash = client.attributes.except('id', 'client_code', 'created_at', 'updated_at', 'approve_create')
      content_hash['client_api_key'] = generate_client_api_key
      content_hash['activation_status'] = client.activation_status.to_s

      array_client_api = []
      client.client_apis.each do |api|
        array_client_api << api.id.to_s
      end
      content_hash[:client_apis] = array_client_api.to_json

      array_insurer = []
      client.insurers.each do |insurer|
        array_insurer << insurer.id.to_s
      end
      content_hash[:insurers] = array_insurer.to_json

      Approval.create(
          table: 'CLIENT',
          row_id: client.id,
          content: content_hash.to_json,
          user: current_user.id
      )
    end

    flash[:notice] = 'Rest Client API Key'
    redirect_to "/client/edit/#{client.id}"
  end

  private

  def client_params
    params.require(:client).permit(:name, :address, :phone, :website_url, :contact_person_name, :contact_person_phone, :contact_person_email, :broker_code, :billing_type, :whitelisted_ip, :activation_status, :client_api_key, client_apis: [], insurers: [] )
  end

  def generate_client_code
    client_code = SecureRandom.random_number(1_000_000_000_000)
    generate_client_code if Client.exists?(client_code: client_code)
    client_code
  end

  def generate_client_api_key
    client_api_key = SecureRandom.hex(24)
    generate_client_api_key if Client.exists?(client_api_key: client_api_key)
    client_api_key
  end

end
