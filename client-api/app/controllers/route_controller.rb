class RouteController < AuthenticationController
  before_action :route_check
  before_action :client_allowed
  before_action :validation, if: :need_validation?
  after_action :create_api_log

  def route_check

    if params[:route].blank?
      render json: ERROR_ROUTE_NOT_MATCH.to_json, status: :not_found
      return
    end

    if $redis.get("#{request.method}/#{params[:route]}").nil?
      render json: ERROR_ROUTE_NOT_MATCH.to_json, status: :not_found
        return
    end

    @api = ClientApi.find_by_path(params[:route])

  end

  def current_client_api
    @api
  end

  def client_allowed
    # client allowed for the client api
    unless current_client.client_apis.where(id: current_client_api.id).any?
      render_error(ERROR_CLIENT_NOT_SUPPORTED, "forbidden")
      create_api_log and return
    end
  end

  def need_validation?
    current_client_api.validation
  end

  def validation

    rp = request.method == "GET" ? request.query_parameters.to_json : request.raw_post
    if rp.blank?
      puts "no request payload from client"
      return
    end

    # if authorization enable
    unless JSON.parse(current_client_api.payloads).blank?
      # puts "client api payload existed"

      unless JSON.parse(rp).blank?
        # puts "request payload existed"

        # validate one by one
        JSON.parse(current_client_api.payloads).each do |payload|

          # validate for parent key
          if payload['is_array'] == 'true' && payload['parent_array'].blank?

            # check for mandatory
            if payload['mandatory'] == 'true'

              # check if key variable is an array
              unless JSON.parse(rp)[payload['key_name']].kind_of?(Array)
                render_error(ERROR_MANDATORY_MISSING, "unprocessable_entity")
                create_api_log and return
              end

            end

          elsif payload['is_array'] != 'true' && !payload['parent_array'].blank? # if is child variable

            # if mandatory
            if payload['mandatory'] == 'true'

              # check if key variable is an array
              unless JSON.parse(rp)[payload['parent_array']].kind_of?(Array)
                render_error(ERROR_MANDATORY_MISSING, "unprocessable_entity")
                create_api_log and return
              end

              # check if child exists in array parent
              unless JSON.parse(rp)[payload['parent_array']].all? { |s| s.has_key?(payload['key_name'])}
                render_error(ERROR_MANDATORY_MISSING, "unprocessable_entity")
                create_api_log and return
              end

            end

            # if enable validation
            if payload['enable_validation'] == 'true' && !payload['validation'].blank?
              if JSON.parse(rp)[payload['parent_array']].kind_of?(Array)
                JSON.parse(rp)[payload['parent_array']].each do |array|
                  next if array[payload['key_name']].blank?

                  validations = payload['validation'].split
                  validations.each do |validation|
                    unless !!(validation.to_regexp =~ array[payload['key_name']].to_s )
                      render_error(ERROR_VALIDATION, "bad_request")
                      create_api_log and return
                    end
                  end


                end
              end
            end


          else

            # if mandatory
            if payload['mandatory'] == 'true'
              unless JSON.parse(rp).key?(payload['key_name'])
                render_error(ERROR_MANDATORY_MISSING, "unprocessable_entity")
                create_api_log and return
              end
            end

            # if enable validation
            if payload['enable_validation'] == 'true' && !payload['validation'].blank?

              validations = payload['validation'].split
              validations.each do |validation|
                unless !!(validation.to_regexp =~ JSON.parse(rp)[payload['key_name']].to_s )
                  render_error(ERROR_VALIDATION, "bad_request")
                  create_api_log and return
                end
              end

            end

          end
        end


      end

    end

  end

  def create_api_log

    @reconnected ||= ClientApiReport.connection.reconnect! || true

    ClientApiReport.delay.create(
        client_id: current_client.nil? ? nil : current_client.id,
        client_api_key: params[:x_token],
        request_ip: request.remote_ip,
        request_endpoint: request.fullpath,
        request_method: request.method,
        request_format: request.headers['Accept'].nil? ? nil : request.headers['Accept'],
        request_payload_format: request.headers['Content-Type'].nil? ? request.format : request.headers['Content-Type'],
        request_payload: request.raw_post.blank? ? nil : JSON.parse(request.raw_post).to_json,
        response_payload: response.body.blank? ? nil : request.headers['Accept'] == 'application/xml' ? Nokogiri.XML(response.body).to_xml : JSON.parse(response.body).to_json,
        client_api_id: current_client_api.nil? ? nil : current_client_api.id,
        response_code: response.code
    )

  end

end
