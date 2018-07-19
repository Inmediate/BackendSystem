class ApiController < RouteController

  before_action :get_insurer
  before_action :match_insurer_api
  before_action :generate_uuid

  def index

    if current_insurer_apis.blank?
      render_error(ERROR_INSURER_NOT_SUPPORTED, "not_found")
      create_api_log and return
    end

    insurerConnector = InsurerConnectorController.new

    # first = proc do
    #   result = []
    #   current_insurer_apis.each do |api|
    #     result << InsurerConnectorController.new.api(current_uuid, api, @request_payload)
    #   end
    # end
    #
    # second = proc do
    #   array_result = Parallel.map(current_insurer_apis, in_thread: 10) do |api|
    #     InsurerConnectorController.new.api(current_uuid, api, @request_payload)
    #   end
    # end

    #calculations
    # puts "second: "
    # time = exec_time( second )
    # puts "time is #{time}\n\r"
    #
    # puts "first: "
    # time = exec_time( first )
    # puts "time is #{time}\n\r"

    array_result = Parallel.map(current_insurer_apis, in_threads: Rails.configuration.max_threads) do |api|
      begin_time = Time.now
      insurer_connector = insurerConnector.api(current_uuid, api, @request_payload)
      end_time = Time.now - begin_time
      insurer_connector["time"] = end_time
      insurer_connector
    end

    # array_result = nil

    # proccess = proc do
    #   array_result = Parallel.map(current_insurer_apis, in_threads: 2) do |api|
    #     ActiveRecord::Base.connection_pool.with_connection do
    #       begin_time = Time.now
    #       insurer_connector = insurerConnector.api(current_uuid, api, @request_payload)
    #       end_time = Time.now - begin_time
    #       insurer_connector
    #     end
    #   end
    # end

    # proccess.call

    if request.headers['Accept'] == 'application/xml'
      render xml: array_result.to_xml(root: 'responses', dasherize: false), status: :ok
    else
      render json: array_result.to_json, status: :ok
    end

    # array_result = []
    # current_insurer_apis.each do |api|
    #   result = InsurerConnectorController.new.api(current_uuid, api, @request_payload)
    #   array_result << result
    # end

  end

  private

  # def exec_time(proc)
  #   begin_time = Time.now
  #   proc.call
  #   Time.now - begin_time
  # end

  def get_insurer
    # bound to specific insurer
    rp = request.method == 'GET' ? request.query_parameters.to_json : request.raw_post
    @request_payload = rp
    @insurers = []
    if !rp.blank? && !JSON.parse(rp)['insurer_company_code'].blank?

      insurers = Insurer.where(company_code: JSON.parse(rp)['insurer_company_code']).where(status: true).where(activation_status: true)

      if insurers.any?

        insurer = insurers.first

        # unless current_client.insurers.where(id: insurer.id).any?
        #   render_error(ERROR_INSURER_NOT_SUPPORTED, "forbidden")
        #   create_api_log and return
        # end

        unless InsurerClient.where(insurer_id: insurer.id).where(client_id: current_client.id).where(product_id: current_client_api.product_id).any?
          render_error(ERROR_INSURER_NOT_SUPPORTED, "forbidden")
          create_api_log and return
        end

        @insurers << insurer
      else
        render_error(ERROR_INSURER_NOT_MATCH, "not_found")
        create_api_log and return
      end

    else
      # get Insurers
      insurer_clients = InsurerClient.where(product_id: current_client_api.product_id).where(client_id: current_client.id)

      if insurer_clients.blank?
        render_error(ERROR_INSURER_NOT_MATCH, "not_found")
        create_api_log and return
      end

      insurer_clients.each do |ic|
        insurer = Insurer.find(ic.insurer_id)
        next unless insurer.status && insurer.activation_status
        @insurers << Insurer.find(ic.insurer_id)
      end

    end
    @insurers
  end

  def current_insurers
    @insurers
  end

  def match_insurer_api

    insurers = get_insurer
    @insurer_apis = []

    if insurers.blank?
      # render json: ERROR_INSURER_NOT_MATCH.to_json, status: :not_found
      render_error(ERROR_INSURER_NOT_MATCH, "not_found")
      create_api_log and return
    end

    if insurers.count > 1

      insurers_blank = true
      insurer_api_blank = true
      insurers.each do |current_insurer|
        next unless current_insurer.status && current_insurer.activation_status
        insurers_blank = false
        current_insurer.insurer_product_apis.where(is_authentication: false).where(status: true).where(activation_status: true).select {|s| s.client_api_id == current_client_api.id}.each do |api|
          @insurer_apis << api
        end

      end

      if insurers_blank
        # render json: ERROR_INSURER_NOT_MATCH.to_json, status: :not_found
        render_error(ERROR_INSURER_NOT_MATCH, "not_found")
        create_api_log and return
      end

      if @insurer_apis.blank?
        # render json: ERROR_INSURER_NOT_SUPPORTED.to_json, status: :not_found
        render_error(ERROR_INSURER_NOT_SUPPORTED, "not_found")
        create_api_log and return
      end

    else

      current_insurer = insurers.first

      @insurer_apis = current_insurer.insurer_product_apis.where(is_authentication: false).where(status: true).where(activation_status: true).select {|s| s.client_api_id == current_client_api.id}

      if @insurer_apis.blank?
        render_error(ERROR_INSURER_NOT_SUPPORTED, "not_found")
        create_api_log and return
      end

    end
  end

  def current_insurer_apis
    @insurer_apis
  end

  def generate_uuid
    @uuid = SecureRandom.uuid
  end

  def current_uuid
    @uuid
  end


end
