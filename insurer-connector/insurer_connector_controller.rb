class InsurerConnectorController < ActionController::Base

  def api(uuid, insurer_api, request_payload)

    @uuid = uuid
    @insurer_api = insurer_api

    hash = {}
    hash[:company_code] = insurer_api.insurer.company_code

    unless insurer_api.status || insurer_api.activation_status
      hash[:response_code] = 403
      hash[:reason] = 'NOT_FOUND'
      return hash
    end

    # check valiation required
    if insurer_api.validation
      hash_validation = validate(insurer_api, request_payload)
      unless hash_validation[:status] == true
        hash[:response_code] = hash_validation[:reason] == 'missing' ? 422 : 400
        hash[:reason] = hash_validation[:reason] == 'missing' ? 'MISSING_INPUTS' : 'VALIDATION_FAILED'
        return hash
      end

    end

    is_live = true

    if insurer_api.cache_policy == 'Live'
      hash_result = live_request(insurer_api, request_payload)
      hash[:payload_type] = content_type?(hash_result[:response_body])
      hash[:response_code] = hash_result[:response_code]

      #handle setting error
      if hash[:response_code] == 503
        hash[:reason] = 'TIMEOUT'
      else
        hash[:response_body] = Base64.strict_encode64(hash_result[:response_body].gsub("\n", ''))
        if !hash[:response_code].between?(200,209)
          hash[:reason] = 'REMOTE_SERVER_ERROR'
        end
      end

    else
      hash_result = database_request(insurer_api , request_payload, nil, false)
      hash[:payload_type] = content_type?(hash_result[:response_body])

      if hash_result[:cache_policy] == 'Live'
        hash[:response_code] = hash_result[:response_code]

        #handle setting error
        if hash[:response_code] == 503
          hash[:reason] = 'TIMEOUT'
        else
          hash[:response_body] = Base64.strict_encode64(hash_result[:response_body].gsub("\n", ''))
          if !hash[:response_code].between?(200,209)
            hash[:reason] = 'REMOTE_SERVER_ERROR'
          end
        end
      else
        is_live = false
        hash[:response_code] = 200
        hash[:response_body] =  Base64.strict_encode64(hash_result[:response_body].gsub("\n", ''))
      end
    end


    hash
  end


  def validate(api, request_payload)

    return_result = {}
    return_result[:status] = false

    # if authorization enable
    unless JSON.parse(api.payload_validation).blank?

      unless JSON.parse(request_payload).blank?

        # validate one by one
        JSON.parse(api.payload_validation).each do |payload|

          # validate for parent key
          if payload['is_array'] == 'true' && payload['parent_array'].blank?

            # check for mandatory
            if payload['mandatory'] == 'true'
              # check if key variable is an array
              unless JSON.parse(request_payload)[payload['name']].kind_of?(Array)
                return_result[:reason] = 'missing'
                return return_result
              end

            end

          elsif payload['is_array'] != 'true' && !payload['parent_array'].blank? # if is child variable

            # if mandatory
            if payload['mandatory'] == 'true'

              # check if key variable is an array
              unless JSON.parse(request_payload)[payload['parent_array']].kind_of?(Array)
                return_result[:reason] = 'missing'
                return return_result
              end

              # check if child exists in array parent
              unless JSON.parse(request_payload)[payload['parent_array']].all? { |s| s.has_key?(payload['name'])}
                return_result[:reason] = 'missing'
                return return_result
              end

            end

            # if enable validation
            if payload['enable_validation'] == 'true' && !payload['validation'].blank?
              if JSON.parse(request_payload)[payload['parent_array']].kind_of?(Array)
                JSON.parse(request_payload)[payload['parent_array']].each do |array|
                  next if array[payload['name']].blank?
                  payload['validation'].split.each do |validation|
                    next if !!(validation.to_regexp =~ array[payload['name']].to_s )
                    return_result[:reason] = 'validation'
                    return return_result
                  end
                end
              end
            end


          else

            # if mandatory
            if payload['mandatory'] == 'true'
              unless JSON.parse(request_payload).key?(payload['name'])
                return_result[:reason] = 'missing'
                return return_result
              end
            end

            # if enable validation
            if payload['enable_validation'] == 'true' && !payload['validation'].blank? && JSON.parse(request_payload).key?(payload['name'])
              payload['validation'].split.each do |validation|
                next if !!(validation.to_regexp =~ JSON.parse(request_payload)[payload['name']].to_s )
                return_result[:reason] = 'validation'
                return return_result
              end
            end

          end
        end


      end

    end

    return_result[:status] = true
    return_result
  end

  def live_request(api, request_payload)

    result = {}

    # replace all variable
    request_payload = replace_variable(api, request_payload)
    response = execute_reponse(api, request_payload)

    # timeout error
    if response == 'time_error'
      result[:response_code] = 503
    else
      result[:response_code] = response.code
      result[:response_body] = response.body.blank? ? "" : response.body
    end
    result[:request_payload] = request_payload
    result
  end

  def database_request(api, request_payload, cache, is_replaced)

    result = {}
    # replace all variable
    rp = is_replaced ? request_payload : replace_variable(api, request_payload)
    payload_sha256 = Digest::SHA256.base64digest(rp.blank? ? '' : rp)

    # get response cache array
    response_cache = cache.nil? ? ResponseCache.where(insurer_product_api_id: api.id).where(payload_sha256: payload_sha256).where(url: api.api_url).first : cache

    # if response cache not exists or expired
    if response_cache.blank? || response_cache.expired_at < Time.now

      response = execute_reponse(api, rp)

      result[:request_payload] = rp
      result[:cache_policy] = 'Live'

      if response == 'time_error'
        result[:response_code] = 503
        return result
      end

      result[:response_code] = response.code
      result[:response_body] = response.body.blank? ? "" : response.body

      if response.success?
        if response_cache.blank?
          response_cache = ResponseCache.delay.create(
              insurer_product_api_id: api.id,
              payload_sha256: payload_sha256,
              request: rp,
              url: api.api_url,
              response: Base64.strict_encode64(response.body.gsub("\n", '')),
              expired_at: Time.now + api.cache_timeout.to_i.hours
          )
        else
          response_cache.delay.update(
              response: Base64.strict_encode64(response.body.gsub("\n", '')),
              expired_at: Time.now + api.cache_timeout.to_i.hours
          )
        end
      end

    else
      result[:cache_policy] = 'Database'
      result[:response_body] = Base64.decode64(response_cache.response)

      unless @uuid.blank?
        #log api here
        hash_response = {
            insurer_product_api_id: api.id,
            request_id: @uuid.to_s,
            source: "Database",
            request_url: '',
            request_method: '',
            request_payload: '',
            response_code: '200',
            response_payload: response_cache.response,
            response_format: content_type?(Base64.decode64(response_cache.response)),
            request_format: '',
        }
        api_log(hash_response)
      end

    end

    #hash result retrun
    result

  end

  def replace_variable(api, request_payload)

    payload_validation = api.payload_validation
    return_payload = api.payload

    # request payload for insurer is blank
    if return_payload.blank?
      return ''
    end

    # request payload from client is blank
    if request_payload.blank? || payload_validation.blank?
      return return_payload
    end

    JSON.parse(payload_validation).each do |variable|

      # standard variable
      if variable['is_array'] == 'false' && variable['parent_array'].blank?
        unless JSON.parse(request_payload)[variable['name']].blank?
          unless variable['mapping'].blank?
            # get mapping values
            insurer_mapping_array = JSON.parse(api.insurer.mapping).select {|s| s['id'] == variable['mapping'].to_s}
            insurer_mapping = insurer_mapping_array.first
            master_array = insurer_mapping['master']
            value_array = insurer_mapping['value']
            index_mapping = master_array.index(JSON.parse(request_payload)[variable['name']].to_s)

            # check if client send mapping value or not. if not send what client is sending
            unless index_mapping.blank?
              value_mapping = value_array[index_mapping.to_i]
              return_payload.sub! "_im_#{variable['name']}", variable['encrypted'] == 'true' ? encrypt_string(value_mapping) : value_mapping.to_s
            else
              return_payload.sub! "_im_#{variable['name']}", variable['encrypted'] == 'true' ? encrypt_string(JSON.parse(request_payload)[variable['name']]) :  JSON.parse(request_payload)[variable['name']].to_s
            end

          else
            return_payload.sub! "_im_#{variable['name']}", variable['encrypted'] == 'true' ? encrypt_string(JSON.parse(request_payload)[variable['name']]) : JSON.parse(request_payload)[variable['name']].to_s
          end
        else
          return_payload.sub! "_im_#{variable['name']}", ''
        end
      end

      # parent variable
      if variable['is_array'] == 'true'

        # convert payload to hash
        hash_payload = {}
        root_name = ''
        if api.payload_type == 'JSON'
          hash_payload = JSON.parse(return_payload).with_indifferent_access
        else
          # doc = Nokogiri::XML(return_payload)
          root_name = Nokogiri::XML(return_payload).root.name
          hash_payload = Hash.from_xml(return_payload.delete("\n")).with_indifferent_access["#{root_name}"]
        end



        # find parent value
        hash_payload.extend Hashie::Extensions::DeepFind
        hash_parent_value = hash_payload.deep_find("_im_#{variable['name']}").first

        # if no variable exist in the payload request
        next if hash_parent_value.blank?

        # if variable not an array
        next if hash_parent_value.kind_of?(Array)

        # prent value that has exact child value (child variable replaced)
        updated_parent_array = []

        # search for child variable in payload validation
        child_pv_array = JSON.parse(payload_validation).select {|s| s['parent_array'] == variable['name']}
        child_pv_array.each do |child_pv|
          break unless JSON.parse(request_payload)[variable['name']].kind_of?(Array)
          # next unless JSON.parse(request_payload)[variable['name']].any? {|s| s[child_pv['name']]}

          # replace variable
          if updated_parent_array.blank?
            JSON.parse(request_payload)[variable['name']].each do |child_rp|

              temp_hash_str = hash_parent_value.to_json

              if child_rp[child_pv['name']].blank?
                temp_hash_str.sub! "_im_#{child_pv['name']}", ''
              else

                unless child_pv['mapping'].blank?
                  # get mapping values
                  insurer_mapping_array = JSON.parse(api.insurer.mapping).select {|s| s['id'] == child_pv['mapping'].to_s}
                  insurer_mapping = insurer_mapping_array.first
                  master_array = insurer_mapping['master']
                  value_array = insurer_mapping['value']
                  index_mapping = master_array.index(child_rp[child_pv['name']].to_s)

                  # check if client send mapping value or not. if not, send what client is sending
                  unless index_mapping.nil?
                    value_mapping = value_array[index_mapping.to_i]
                    temp_hash_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(value_mapping) : value_mapping.to_s
                  else
                    temp_hash_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(child_rp[child_pv['name']]) : child_rp[child_pv['name']].to_s
                  end

                else
                  temp_hash_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(child_rp[child_pv['name']]) : child_rp[child_pv['name']].to_s
                end

              end


              updated_parent_array << JSON.parse(temp_hash_str)

            end
          else
            updated_parent_array.each_with_index do |temp_child_rp, index|

              temp_child_rp_str = temp_child_rp.to_json
              if JSON.parse(request_payload)[variable['name']][index][child_pv['name']].blank?
                temp_child_rp_str.gsub!("_im_#{child_pv['name']}", '')
              else

                unless child_pv['mapping'].blank?
                  # get mapping values
                  insurer_mapping_array = JSON.parse(api.insurer.mapping).select {|s| s['id'] == child_pv['mapping'].to_s}
                  insurer_mapping = insurer_mapping_array.first
                  master_array = insurer_mapping['master']
                  value_array = insurer_mapping['value']
                  index_mapping = master_array.index(JSON.parse(request_payload)[variable['name']][index][child_pv['name']].to_s)

                  # check if client send mapping value or not. if not send what client is sending
                  unless index_mapping.nil?
                    value_mapping = value_array[index_mapping.to_i]
                    temp_child_rp_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(value_mapping) : value_mapping.to_s
                  else
                    temp_child_rp_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(JSON.parse(request_payload)[variable['name']][index][child_pv['name']]) : JSON.parse(request_payload)[variable['name']][index][child_pv['name']].to_s
                  end

                else
                  temp_child_rp_str.sub! "_im_#{child_pv['name']}", child_pv['encrypted'] == 'true' ? encrypt_string(JSON.parse(request_payload)[variable['name']][index][child_pv['name']]) : JSON.parse(request_payload)[variable['name']][index][child_pv['name']].to_s
                end

              end

              updated_parent_array[index] = JSON.parse(temp_child_rp_str)
            end
          end

        end

        # if parent object is not blank?
        unless updated_parent_array.blank?
          # array variable replace
          if api.payload_type == 'JSON'
            hash_payload["_im_#{variable['name']}"] = updated_parent_array
          else
            hash_payload["_im_#{variable['name']}"] = updated_parent_array
          end
        end



        # convert back to JSON or XML
        return_payload = if api.payload_type == 'JSON'
                           hash_payload.to_json
                         else
                           hash_payload.to_xml(root: root_name, dasherize: false)
                         end

        return_payload.gsub!("_im_#{variable['name']}", variable['name'])

      end

    end

    return_payload
  end

  def execute_reponse(api, request_payload)

    #set header
    header = {}
    unless api.headers.blank?
      JSON.parse(api.headers).each do |sh|
        header["#{sh['head'].strip}"] = sh['value'].strip
      end
    end

    #set body
    body = request_payload.blank? ? '' : request_payload

    # api flavor
    response = if api.api_flavour == 'Type 1'
                 request_api(api, body, header)
              elsif api.api_flavour == 'Type 2'
                 af_2(api, body, header)
              elsif api.api_flavour == 'Type 3'
                  af_3(api, body, header)
               end

    response
  end


  def af_2(api, body, header)

    auth_scheme_name = api.auth_scheme_name
    credential = api.credential

    auth = auth_scheme_name.gsub '_im_token', credential

    header['Authorization'] = auth

    response = request_api(api, body, header)

    response

  end

  def af_3(api, body, header)

    puts "Type Flavour 3"

    response = nil
    credential_response = nil
    response_body = nil

    auth_scheme_name = api.auth_scheme_name
    auth_api = InsurerProductApi.find(api.auth_api)
    auth_api_body = auth_api.payload

    if auth_api.cache_policy == 'Live'

      # get authentication api details
      auth_api_header = {}
      JSON.parse(auth_api.headers).each do |sh|
        auth_api_header["#{sh['head'].strip}"] = sh['value'].strip
      end

      case auth_api.api_flavour
        when 'Type 2'
          credential_response = af_2(auth_api, auth_api_body, auth_api_header)
        when 'Type 3'
          credential_response = af_3(auth_api, auth_api_body, auth_api_header)
        when 'Type 1'
          credential_response = request_api(auth_api, auth_api_body, auth_api_header)
      end

      response_body = credential_response == 'time_error' ? nil : credential_response.body

    else

      payload_sha256 = Digest::SHA256.base64digest(auth_api_body)
      # get response cache array
      response_cache = ResponseCache.where(insurer_product_api_id: auth_api.id).where(payload_sha256: payload_sha256).where(url: api.api_url).first
      # if nil
      if response_cache.blank? || response_cache.expired_at < Time.now
        # create new response (request api)
        auth_api_header = {}
        JSON.parse(auth_api.headers).each do |sh|
          auth_api_header["#{sh['head'].strip}"] = sh['value'].strip
        end

        case auth_api.api_flavour
          when 'Type 2'
            credential_response = af_2(auth_api, auth_api_body, auth_api_header)
          when 'Type 3'
            credential_response = af_3(auth_api, auth_api_body, auth_api_header)
          when 'Type 1'
            credential_response = request_api(auth_api, auth_api_body, auth_api_header)
        end

        # timeout
        if credential_response == 'time_error'
          response_body = nil
        else
          if credential_response.success?

            if response_cache.blank?
              response_cache = ResponseCache.delay.create(
                  insurer_product_api_id: auth_api.id,
                  payload_sha256: payload_sha256,
                  request: auth_api_body,
                  url: auth_api.api_url,
                  response: credential_response.body,
                  expired_at: Time.now + auth_api.cache_timeout.to_i.hours
              )
            else
              response_cache.delay.update(
                  response: credential_response.body,
                  expired_at: Time.now + auth_api.cache_timeout.to_i.hours
              )
            end

          end

          # get from request api
          response_body = credential_response.body

        end

      else
        # get from cache response table
        response_body = response_cache.response
      end
    end


    auth_token_array = auth_api.auth_token_key_name.split('//')
    puts "auth_token_array: #{auth_token_array}"
    auth_token_count = auth_token_array.count.to_i
    current_hash = {}

    unless response_body.blank?
      current_hash = if content_type?(response_body) == 'XML'
                       Hash.from_xml(response_body.delete("\n")).with_indifferent_access
                     elsif content_type?(response_body) == 'JSON'
                       if valid_json?(response_body)
                         JSON.parse(response_body).with_indifferent_access
                       else
                         {}
                       end
                     end
    end

    credential_key = current_hash

    auth_token_array.each do |value|
      next if credential_key["#{value}"].blank?
      credential_key = credential_key["#{value}"]
    end

    if credential_key.blank?
      credential_key = ''
    end

    auth = auth_scheme_name.gsub('_im_token',credential_key.to_s)

    header['Authorization'] = auth

    response = request_api(api, body, header)

    response

  end

  def request_api(api, body, header)
    response = 'time_error'

    # puts "api url : #{api.api_url}"
    # puts "api method : #{api.api_method}"
    # puts "api body : #{body}"
    puts "api header : #{header}"

    header = if header.blank?
               if api.api_method == 'GET'
                 {"Accept"=> "application/json"}
               else
                 {"Accept"=> "application/#{api.payload_type == 'JSON' ?'json' : 'xml'}", "Content-Type" => "application/#{api.payload_type == 'JSON' ?'json' : 'xml'}"}
               end
             else
               if api.api_method == 'GET' || header.key?('Content-Type') || header.key?('content-type')
                 if  header.key?('Accept') || header.key?('Accept')
                   header
                 else
                   header["Accept"] = "application/#{api.payload_type == 'JSON' ? 'json' : 'xml'}"
                   header
                 end
               else
                 header["Content-Type"] = "application/#{api.payload_type == 'JSON' ? 'json' : 'xml'}"
                 if  header.key?('Accept') || header.key?('Accept')
                   header
                 else
                   header["Accept"] = "application/#{api.payload_type == 'JSON' ? 'json' : 'xml'}"
                   header
                 end
               end
             end

    puts "header #{api.insurer.company_code}: #{header}"

    begin
      case api.api_method
        when 'POST'
          response = HTTParty.post(api.api_url, body: body, headers: header)
        when 'PATCH'
          response = HTTParty.patch(api.api_url, body: body, headers: header)
        when 'PUT'
          response = HTTParty.put(api.api_url, body: body, headers: header)
        when 'DELETE'
          response = HTTParty.delete(api.api_url, body: body, headers: header)
        when 'GET'
          response = HTTParty.get(api.api_url, query: body.blank? ? nil : JSON.parse(body), headers: header)
      end
    rescue HTTParty::Error => e
      # ErrorHandler.handle(e)
      response = 'time_error'
    rescue SocketError => e
      # ErrorHandler.handle(e, :warn)
      response = 'time_error'
    rescue Errno::ECONNREFUSED => e
      # ErrorHandler.handle(e)
      response = 'time_error'
    rescue StandardError
      response = 'time_error'
    end

    cron_uuid = ''
    if @uuid.blank?
      cron_uuid = SecureRandom.uuid
      cron_uuid[0,5] = 'cron-'
    end

    #log api here
    hash_response = {
        insurer_product_api_id: api.id,
        request_id: @uuid.blank? ? cron_uuid : @uuid.to_s,
        source: "Live",
        request_url: api.api_url,
        request_method: api.api_method,
        request_payload: body,
        response_code: response == 'time_error' ? '503' : response.code,
        response_payload: response == 'time_error' ? '' : response.body,
        response_format: response == 'time_error' ? '' : content_type?(response.body),
        request_format: api.payload_type,
    }
    api_log(hash_response)

    response
  end

  def encrypt_string(value)

    begin
      public_key = OpenSSL::PKey::RSA.new(@insurer_api.RSA_encrypt_public_key)
    rescue
      puts 'Failed to create Public Key'
      return value
    end

    Base64.encode64(public_key.public_encrypt(value.to_s)).gsub("\n", '')
  end

  def content_type?(response_body)
    return 'JSON' if response_body.blank?

    if Nokogiri::XML(response_body).errors.blank?
      return 'XML'
    end
    #else return JSON
    return 'JSON'
  end

  def valid_json?(json)
    JSON.parse(json)
    true
  rescue
    false
  end

  def get_hash_level(hash, key)
    return key if hash.key?(key)

    # loop for array or object
    hash.select {|s| s.kind_of?(Array) || s.kind_of?(Hash)}.each do |object|
      return level if object.key?(key)
    end

  end

  def api_log(hash)
    InsurerProductApiReport.delay.create(
        insurer_product_api_id: hash[:insurer_product_api_id],
        request_id: hash[:request_id],
        source: hash[:source],
        request_url: hash[:request_url],
        request_method: hash[:request_method],
        request_payload: hash[:request_payload],
        response_code: hash[:response_code],
        response_payload: hash[:response_payload],
        response_format: hash[:response_format],
        request_format: hash[:request_format]
    )
  end


end
