class InsurerProductApiController < InsurerController

  before_action :redirect_not_admin, only: %i[approve approve_create reject reject_delete]
  before_action :redirect_cannot_delete, only: %i[delete]


  def new
    @insurer = Insurer.find(params[:insurer_id])
    @api = InsurerProductApi.new()
    @client_api = []
    ClientApi.where(status: true).where(activation_status: true).each do |client_api|
      next if @insurer.insurer_product_apis.any? { |s| s.client_api_id == client_api.id}
      @client_api << client_api
    end
    @insurer_mapping = []
    @insurer_mapping_id_array = []
    @insurer_mapping_name_array = []

    unless @insurer.mapping.blank?
      @insurer_mapping  = JSON.parse(@insurer.mapping)

      # array of id mapping
      JSON.parse(@insurer.mapping).each do |map|
        @insurer_mapping_id_array << map['id']
      end

      # array of name mapping
      @insurer_mapping_id_array.each do |id|
        @insurer_mapping_name_array << Mapping.find(id).name
      end

    end

    add_breadcrumb @insurer.company_name, "/insurer/edit/#{@insurer.id}"
    add_breadcrumb "Insurer Product API"
    add_breadcrumb "New"

  end

  def create
    insurer = Insurer.find(params[:insurer_id])

    # if authentication api
    if params[:insurer_product_api]['is_authentication'] == "1"
      if params[:insurer_product_api]['auth_token_key_name'].blank?
        flash.now[:error] = 'Authentication Token Key Name is required.'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end
    else
      if params[:insurer_product_api]['client_api_id'].blank?
        flash.now[:error] = 'Client API Mapping is required.'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end
    end

    # required params nil
    if params[:insurer_product_api]['api_url'].blank?
      flash.now[:error] = 'API URL is required.'
      # redirect_to "/insurer/#{insurer.id}/api/new"
      new
      @api = InsurerProductApi.new(insurer_api_params)
      render :new
      return
    end

    if params[:insurer_product_api]['api_method'].blank?
      flash.now[:error] = 'API Method is required'
      # redirect_to "/insurer/#{insurer.id}/api/new"
      new
      @api = InsurerProductApi.new(insurer_api_params)
      render :new
      return
    end

    if params[:insurer_product_api]['api_flavour'].blank?
      flash.now[:error] = 'API Flavor is required'
      # redirect_to "/insurer/#{insurer.id}/api/new"
      new
      @api = InsurerProductApi.new(insurer_api_params)
      render :new
      return
    end

    # if API flavor type 2
    if params[:insurer_product_api]['api_flavour'] == "Type 2"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['credential'].blank?
        flash.now[:error] = 'Pre-Shared Credential is required if API flavor Type 2 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end

    end

    # if API flavor type 3
    if params[:insurer_product_api]['api_flavour'] == "Type 3"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['auth_api'].blank?
        flash.now[:error] = 'Authentication API is required if API flavor Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end
    end

    # check api end_point duplicate at Live table
    if insurer.insurer_product_apis.any? { |s| "#{s.api_method}#{s.api_url}" == "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" }
      flash.now[:error] = "API end point already exists. It has to be unique"
      # redirect_to "/insurer/#{insurer.id}/api/new"
      new
      @api = InsurerProductApi.new(insurer_api_params)
      render :new
      return
    end

    # check for duplicate path at Cache table
    approval = Approval.where(table: 'INSURER_PRODUCT_API')
    unless approval.blank?
      approval.each do |cache|
        if "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" ==  "#{JSON.parse(cache.content)['api_method']}#{JSON.parse(cache.content)['api_url']}"
          flash.now[:error] = 'API end point alredy exists in Cache Table. It has to be unique'
          # redirect_to "/insurer/#{insurer.id}/api/new"
          new
          @api = InsurerProductApi.new(insurer_api_params)
          render :new
          return
        end
      end
    end

    # payload type and payload
    unless params[:insurer_product_api]['payload'].blank?
      if params[:insurer_product_api]['payload_type'] == 'JSON'
        unless valid_json?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/new"
          new
          @api = InsurerProductApi.new(insurer_api_params)
          render :new
          return
        end
      end

      if params[:insurer_product_api]['payload_type'] == 'XML'
        unless valid_xml?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/new"
          new
          @api = InsurerProductApi.new(insurer_api_params)
          render :new
          return
        end
      end
    end

    # get payload validation
    payload_validations = []
    unless params[:insurer_product_api]['payload_validation'].nil?

      if params[:insurer_product_api]['payload_validation'].all? {|s| s['name'].blank?}
        flash.now[:error] = 'Variable Name of Payload Validation is required.'
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end


      # check for duplicate payload variable name
      unless params[:insurer_product_api]['payload_validation'].count == params[:insurer_product_api]['payload_validation'].uniq{ |s| s['name'] }.count
        flash.now[:error] = 'Variable Name of Payload Validation must be unique. Please try again.'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end

      payload_validations = params[:insurer_product_api]['payload_validation']

    end

    # get header
    headers = []
    unless params[:insurer_product_api]['headers'].nil?

      # check for duplicate
      unless params[:insurer_product_api]['headers'].count == params[:insurer_product_api]['headers'].uniq{ |s| s['head'] }.count
        flash.now[:error] = 'Header Name of Static Header must be unique. Please try again.'
        # redirect_to "/insurer/#{insurer.id}/api/new"
        new
        @api = InsurerProductApi.new(insurer_api_params)
        render :new
        return
      end

      headers = params[:insurer_product_api]['headers']
    end

    custom_insurer_api_params = insurer_api_params.except('payload_validation', 'headers')
    custom_insurer_api_params[:payload_validation] = payload_validations.to_json
    custom_insurer_api_params[:headers] = headers.to_json
    custom_insurer_api_params[:activation_status] = insurer_api_params[:activation_status].blank? ? 'false' : insurer_api_params[:activation_status]
    Approval.create(
        table: 'INSURER_PRODUCT_API',
        content:  custom_insurer_api_params.to_json,
        user: current_user.id
    )

    flash[:success] = 'Success create new Insurer Product API'
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def edit_pending

    if Insurer.where(id: params[:insurer_id]).blank?
      redirect_to insurer_list_path
      return
    end

    @insurer = Insurer.find(params[:insurer_id])
    @api = InsurerProductApi.new
    @client_api = []
    ClientApi.where(status: true).where(activation_status: true).each do |client_api|
      next if @insurer.insurer_product_apis.any? { |s| s.client_api_id == client_api.id}
      @client_api << client_api
    end
    @insurer_mapping = []
    @insurer_mapping_id_array = []
    @insurer_mapping_name_array = []

    unless @insurer.mapping.blank?
      @insurer_mapping  = JSON.parse(@insurer.mapping)

      # array of id mapping
      JSON.parse(@insurer.mapping).each do |map|
        @insurer_mapping_id_array << map['id']
      end

      # array of name mapping
      @insurer_mapping_id_array.each do |id|
        @insurer_mapping_name_array << Mapping.find(id).name
      end

    end

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to "/insurer/edit/#{@insurer.id}"
      return
    end

    @approval = Approval.find(params[:approval_id])
    flash.now[:alert] = "This new Insurer Product API is yet to be approved. What would you want to do? <a href='/insurer/#{@insurer.id}/api/approve_create/#{@approval.id}'><strong>APPROVE</strong></a> | <a href='/insurer/#{@insurer.id}/api/reject_delete/#{@approval.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate

    @api_pending = JSON.parse(@approval.content)
    @payload_validation_pending = JSON.parse(@api_pending['payload_validation'])
    @headers_pending = JSON.parse(@api_pending['headers'])
    @pending_is_auth_api = @api_pending['is_authentication'] == "1" ? true : false
    @pending_is_validation = @api_pending['validation '] == "1" ? true : false

    add_breadcrumb @insurer.company_name, "/insurer/edit/#{@insurer.id}"
    add_breadcrumb "Insurer Product API"
    add_breadcrumb "Edit"
  end

  def update_pending

    if Insurer.where(id: params[:insurer_id]).blank?
      redirect_to insurer_list_path
      return
    end

    insurer = Insurer.find(params[:insurer_id])

    if Approval.where(id: params[:approval_id]).blank?
      redirect_to "/insurer/edit/#{insurer.id}"
      return
    end

    approval = Approval.find(params[:approval_id])

    # if authentication api
    if params[:insurer_product_api]['is_authentication'] == "1"
      if params[:insurer_product_api]['auth_token_key_name'].blank?
        flash.now[:error] = 'Authentication Token Key Name is required.'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end
    else
      if params[:insurer_product_api]['client_api_id'].blank?
        flash.now[:error] = 'Client API Mapping is required.'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end
    end

    # required params nil
    if params[:insurer_product_api]['api_url'].blank?
      flash.now[:error] = 'API URL is required.'
      edit_pending
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      @api = InsurerProductApi.new(insurer_api_params)
      render :edit_pending
      return
    end

    if params[:insurer_product_api]['api_method'].blank?
      flash.now[:error] = 'API Method is required'
      edit_pending
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      @api = InsurerProductApi.new(insurer_api_params)
      render :edit_pending
      return
    end

    if params[:insurer_product_api]['api_flavour'].blank?
      flash.now[:error] = 'API Flavor is required'
      edit_pending
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      @api = InsurerProductApi.new(insurer_api_params)
      render :edit_pending
      return
    end

    # if API flavor type 2
    if params[:insurer_product_api]['api_flavour'] == "Type 2"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['credential'].blank?
        flash.now[:error] = 'Pre-Shared Credential is required if API flavor Type 2 is selected'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

    end

    # if API flavor type 3
    if params[:insurer_product_api]['api_flavour'] == "Type 3"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['auth_api'].blank?
        flash.now[:error] = 'Authentication API is required if API flavor Type 3 is selected'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end
    end

    # check api url duplicate at Live table
    if insurer.insurer_product_apis.where(status:true).any? { |s| "#{s.api_method}#{s.api_url}" == "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" }
      flash.now[:error] = "API end point already exists. It has to be unique"
      edit_pending
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      @api = InsurerProductApi.new(insurer_api_params)
      render :edit_pending
      return
    end

    # check for duplicate path at Cache table
    approvals = Approval.where(table: 'INSURER_PRODUCT_API')
    unless approvals.blank?
      approvals.each do |cache|
        if "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" != "#{approval.parse_content['api_method']}#{approval.parse_content['api_url']}" && "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" ==  "#{JSON.parse(cache.content)['api_method']}#{JSON.parse(cache.content)['api_url']}"
          flash.now[:error] = 'API end point alredy exists in Cache Table. It has to be unique'
          # redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
          edit_pending
          @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
          @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
          @api = InsurerProductApi.new(insurer_api_params)
          render :edit_pending
          return
        end
      end
    end

    # payload type and payload
    unless params[:insurer_product_api]['payload'].blank?
      if params[:insurer_product_api]['payload_type'] == 'JSON'
        unless valid_json?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
          edit_pending
          @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
          @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
          @api = InsurerProductApi.new(insurer_api_params)
          render :edit_pending
          return
        end
      end

      if params[:insurer_product_api]['payload_type'] == 'XML'
        unless valid_xml?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
          edit_pending
          @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
          @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
          @api = InsurerProductApi.new(insurer_api_params)
          render :edit_pending
          return
        end
      end
    end

    # get payload validation
    payload_validations = []
    unless params[:insurer_product_api]['payload_validation'].nil?

      if params[:insurer_product_api]['payload_validation'].all? {|s| s['name'].blank?}
        flash.now[:error] = 'Variable Name of Payload Validation is required.'
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

      # check for duplicate payload variable name
      unless params[:insurer_product_api]['payload_validation'].count == params[:insurer_product_api]['payload_validation'].uniq{ |s| s['name'] }.count
        flash.now[:error] = 'Variable Name of Payload Validation must be unique. Please try again.'
        # redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

      payload_validations = params[:insurer_product_api]['payload_validation']

    end

    # get header
    headers = []
    unless params[:insurer_product_api]['headers'].nil?

      # check for duplicate
      unless params[:insurer_product_api]['headers'].count == params[:insurer_product_api]['headers'].uniq{ |s| s['head'] }.count
        flash.now[:error] = 'Header Name of Static Header must be unique. Please try again.'
        # redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
        edit_pending
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        @api = InsurerProductApi.new(insurer_api_params)
        render :edit_pending
        return
      end

      headers = params[:insurer_product_api]['headers']
    end

    custom_insurer_api_params = insurer_api_params.except('payload_validation', 'headers')
    custom_insurer_api_params[:payload_validation] = payload_validations.to_json
    custom_insurer_api_params[:headers] = headers.to_json
    custom_insurer_api_params[:activation_status] = insurer_api_params[:activation_status].blank? ? JSON.parse(approval.content)['activation_status'] : insurer_api_params[:activation_status]

    approval.update(content: custom_insurer_api_params.to_json, user: current_user.id)

    flash[:success] = 'Success create new Insurer Product API'
    redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"

  end

  def edit

    if Insurer.where(id: params[:insurer_id]).blank?
      redirect_to insurer_list_path
      return
    end

    @insurer = Insurer.find(params[:insurer_id])
    @api = InsurerProductApi.find(params[:id])
    @client_api = []
    @api.client_api_id.blank? ? nil : @client_api << ClientApi.find(@api.client_api_id)
    ClientApi.where(status: true).where(activation_status: true).each do |client_api|
      next if @insurer.insurer_product_apis.where(status: true).any? { |s| s.client_api_id == client_api.id}
      @client_api << client_api
    end
    @insurer_mapping = []
    @insurer_mapping_id_array = []
    @insurer_mapping_name_array = []

    unless @insurer.mapping.blank?
      @insurer_mapping  = JSON.parse(@insurer.mapping)

      # array of id mapping
      JSON.parse(@insurer.mapping).each do |map|
        @insurer_mapping_id_array << map['id']
      end

      # array of name mapping
      @insurer_mapping_id_array.each do |id|
        @insurer_mapping_name_array << Mapping.find(id).name
      end

    end

    approval = Approval.where(table: 'INSURER_PRODUCT_API').where(row_id: @api.id)
    @is_pending = false
    if approval.any?
      flash.now[:alert] = "This Insurer Product API is yet to be approved. What would you want to do? <a href='/insurer/#{@insurer.id}/api/approve/#{@api.id}'><strong>APPROVE</strong></a> | <a href='/insurer/#{@insurer.id}/api/reject/#{@api.id}'><strong>REJECT</strong></></a>".html_safe if can_approve_reject_deactivate
      @api_pending = JSON.parse(approval.first.content)
      @pending_is_auth_api = @api_pending['is_authentication'] == "1" ? true : false
      @pending_is_validation = @api_pending['validation'] == "1" ? true : false
      @is_pending = true
    end

    add_breadcrumb @insurer.company_name, "/insurer/edit/#{@insurer.id}"
    add_breadcrumb "Insurer Product API"
    add_breadcrumb "Edit"
  end

  def update

    if Insurer.where(id: params[:insurer_id]).blank?
      redirect_to insurer_list_path
      return
    end

    insurer = Insurer.find(params[:insurer_id])

    if InsurerProductApi.where(id: params[:id]).blank?
      redirect_to "/insurer/edit/#{insurer.id}"
      return
    end

    insurer_api = InsurerProductApi.find(params[:id])

    # if authentication api
    if params[:insurer_product_api]['is_authentication'] == "1"
      if params[:insurer_product_api]['auth_token_key_name'].blank?
        flash.now[:error] = 'Authentication Token Key Name is required.'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end
    else
      if params[:insurer_product_api]['client_api_id'].blank?
        flash.now[:error] = 'Client API Mapping is required.'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end
    end

    # required params nil
    if params[:insurer_product_api]['api_url'].blank?
      flash.now[:error] = 'API URL is required.'
      # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
      edit
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      render :edit
      return
    end

    if params[:insurer_product_api]['api_method'].blank?
      flash.now[:error] = 'API Method is required'
      # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
      edit
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      render :edit
      return
    end

    if params[:insurer_product_api]['api_flavour'].blank?
      flash.now[:error] = 'API Flavor is required'
      # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
      edit
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      render :edit
      return
    end

    # if API flavor type 2
    if params[:insurer_product_api]['api_flavour'] == "Type 2"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['credential'].blank?
        flash.now[:error] = 'Pre-Shared Credential is required if API flavor Type 2 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

    end

    # if API flavor type 3
    if params[:insurer_product_api]['api_flavour'] == "Type 3"

      # if auth scheme name is nil
      if params[:insurer_product_api]['auth_scheme_name'].blank?
        flash.now[:error] = 'Authentication Scheme Name is required if API flavor Type 2 or Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

      # if pre-shared credential is nil
      if params[:insurer_product_api]['auth_api'].blank?
        flash.now[:error] = 'Authentication API is required if API flavor Type 3 is selected'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end
    end

    # check api url duplicate at Live table
    if insurer_api.api_url != params[:insurer_product_api]['api_url'] && insurer.insurer_product_apis.where(status:true).any? { |s| "#{s.api_method}#{s.api_url}" == "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" }
      flash.now[:error] = "API end point already exists. It has to be unique"
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
      edit
      @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
      @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
      render :edit
      return
    end

    # check for duplicate path at Cache table
    approvals = Approval.where(table: 'INSURER_PRODUCT_API')
    unless approvals.blank?
      approvals.each do |cache|
        unless cache.row_id == insurer_api.id
          if "#{params[:insurer_product_api]['api_method']}#{params[:insurer_product_api]['api_url']}" == "#{JSON.parse(cache.content)['api_method']}#{JSON.parse(cache.content)['api_url']}"
            flash.now[:error] = 'API end point alredy exists in Cache Table. It has to be unique'
            # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
            edit
            @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
            @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
            render :edit
            return
          end
        end
      end
    end

    # payload type and payload
    unless params[:insurer_product_api]['payload'].blank?
      if params[:insurer_product_api]['payload_type'] == 'JSON'
        unless valid_json?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
          edit
          @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
          @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
          render :edit
          return
        end
      end

      if params[:insurer_product_api]['payload_type'] == 'XML'
        unless valid_xml?(params[:insurer_product_api]['payload'])
          flash.now[:error] = 'Invalid Payload format'
          # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
          edit
          @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
          @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
          render :edit
          return
        end
      end
    end

    # get payload validation
    payload_validations = []
    unless params[:insurer_product_api]['payload_validation'].blank?

      if params[:insurer_product_api]['payload_validation'].all? {|s| s['name'].blank?}
        flash.now[:error] = 'Variable Name of Payload Validation is required.'
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

      # check for duplicate
      unless params[:insurer_product_api]['payload_validation'].count == params[:insurer_product_api]['payload_validation'].uniq{ |s| s['name'] }.count
        flash.now[:error] = 'Variable Name of Payload Validation must be unique. Please try again.'
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

      payload_validations = params[:insurer_product_api]['payload_validation']

    end

    # get header
    headers = []
    unless params[:insurer_product_api]['headers'].blank?

      # check for duplicate
      unless params[:insurer_product_api]['headers'].count == params[:insurer_product_api]['headers'].uniq{ |s| s['head'] }.count
        flash.now[:error] = 'Header Name of Static Header must be unique. Please try again.'
        # redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
        edit
        @pending_is_auth_api = params[:insurer_product_api]['is_authentication'] == "1" ? true : false
        @pending_is_validation = params[:insurer_product_api]['validation'] == "1" ? true : false
        render :edit
        return
      end

      headers = params[:insurer_product_api]['headers']

    end

    custom_insurer_api_params = insurer_api_params.except('payload_validation', 'headers')
    custom_insurer_api_params[:payload_validation] = payload_validations.to_json
    custom_insurer_api_params[:headers] = headers.to_json
    custom_insurer_api_params[:activation_status] = insurer_api_params[:activation_status].blank? ? insurer_api.activation_status.to_s : insurer_api_params[:activation_status]

    # get approval
    approval = Approval.where(table: 'INSURER_PRODUCT_API').where(row_id: insurer_api.id)

    if approval.any?
      approval.first.update(content:  custom_insurer_api_params.to_json, user: current_user.id)
    else
      Approval.create(
          table: 'INSURER_PRODUCT_API',
          row_id: insurer_api.id,
          content:  custom_insurer_api_params.to_json,
          user: current_user.id
      )
    end

    flash[:success] = 'Save changes Insurer Product API'
    redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"

  end

  def delete
    insurer = Insurer.find(params[:insurer_id])
    insurer_api = InsurerProductApi.find(params[:id])
    Approval.where(table:'INSURER_PRODUCT_API').where(row_id: insurer_api.id).destroy_all
    insurer_api.update(
        status: false # change status
    )
    unless insurer_api.save
      flash[:error] = 'Failed deleting Insurer Product API'
    else
      flash[:success] = 'Deleted Insurer Product API'
    end

    redirect_to "/insurer/edit/#{insurer.id}"
  end

  def approve
    insurer = Insurer.find(params[:insurer_id])
    insurer_api = InsurerProductApi.find(params[:id])
    approval = Approval.where(table:'INSURER_PRODUCT_API').find_by_row_id(insurer_api.id)
    approval_hash = JSON.parse(approval.content)

    if approval_hash['client_api_id'].nil?
      approval_hash[:client_api_id] = nil
    end

    unless JSON.parse(approval.content)['client_api_id'].blank?
      if insurer.insurer_product_apis.where.not(id: insurer_api.id).where(status: true).any? { |s| s.client_api_id == JSON.parse(approval.content)['client_api_id'].to_i}
        flash[:error] = 'Client Api Mapping must be unique. Please try again'
        redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
        return
      end
    end

    insurer_api.update(approval_hash)

    unless insurer_api.save
      flash[:error] = 'Somethings wrong. Try again.'
    else

      # send to author
      author = User.find(approval.user)
      if author.role_id == 3
        ApprovalMailer.delay.approve_update(author, "approved", current_user.name, "Insurer Product API",  "#{insurer_api.api_method} #{insurer_api.api_url}")
      end
      # send to admin
      User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
        ApprovalMailer.delay.approve_update(user, "approved", current_user.name, "Insurer Product API",  "#{insurer_api.api_method} #{insurer_api.api_url}")
      end

      approval.destroy
      flash[:success] = 'Save changes Insurer Product API is approved.'
    end

    redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
  end

  def approve_create
    insurer = Insurer.find(params[:insurer_id])
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to "/insurer/edit/#{insurer.id}"
      return
    end

    unless JSON.parse(approval.content)['client_api_id'].blank?
      if insurer.insurer_product_apis.where(status: true).any? { |s| s.client_api_id == JSON.parse(approval.content)['client_api_id'].to_i}
        flash[:error] = 'Client Api Mapping must be unique. Please try again'
        redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
        return
      end
    end

    insurer_api = InsurerProductApi.create(JSON.parse(approval.content))

    unless insurer_api.save
      flash[:error] = 'Somethings wrong. Please try again'
      redirect_to "/insurer/#{insurer.id}/api/edit_pending/#{approval.id}"
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "approved", current_user.name, "Insurer Product API")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "approved", current_user.name, "Insurer Product API")
    end
    approval.destroy

    flash[:success] = 'Create new Insurer Product API is approved.'
    redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
  end

  def reject
    insurer = Insurer.find(params[:insurer_id])
    insurer_api = InsurerProductApi.find(params[:id])
    approval = Approval.where(table:'INSURER_PRODUCT_API').find_by_row_id(insurer_api.id)

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_update(author, "rejected", current_user.name, "Insurer Product API",  "#{insurer_api.api_method} #{insurer_api.api_url}")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_update(user, "rejected", current_user.name, "Insurer Product API",  "#{insurer_api.api_method} #{insurer_api.api_url}")
    end
    approval.destroy
    flash[:success] = 'Save changes Insurer Product API is rejected.'
    redirect_to "/insurer/#{insurer.id}/api/edit/#{insurer_api.id}"
  end

  def reject_delete
    insurer = Insurer.find(params[:insurer_id])
    approval = Approval.find(params[:approval_id])

    if approval.nil?
      redirect_to "/insurer/edit/#{insurer.id}"
      return
    end

    # send to author
    author = User.find(approval.user)
    if author.role_id == 3
      ApprovalMailer.delay.approve_create(author, "rejected", current_user.name, "Insurer Product API")
    end
    # send to admin
    User.where(role_id: 1..2).where(status: true).where(activation_status: true).each do |user|
      ApprovalMailer.delay.approve_create(user, "rejected", current_user.name, "Insurer Product API")
    end
    approval.destroy
    flash[:success] = 'Add new Insurer Product API is rejected.'
    redirect_to "/insurer/edit/#{insurer.id}"
  end

  private
  def insurer_api_params
    params.require(:insurer_product_api).permit(:is_authentication, :auth_token_key_name, :client_api_id, :insurer_id, :cache_policy, :cache_timeout, :api_url, :api_method, :api_flavour, :auth_scheme_name, :credential, :auth_api, :payload_type, :payload, :RSA_encrypt_public_key, :validation, :activation_status, payload_validation: [], headers: [] )
  end

  def valid_json?(json)
    JSON.parse(json)
    true
  rescue
    false
  end

  def valid_xml?(xml)
    Nokogiri::XML(xml).errors.blank?
  end

end
