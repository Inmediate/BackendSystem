namespace :cron do

  desc 'Alert for pending approval'
  task pending_approval: :environment do
    # puts 'rake pending start'

    #get all pending approval
    approvals = Approval.all

    #get all Admin and Super Admin
    admins = User.where.not(role_id: 3).where(status: true).where(activation_status: true).where(accept_invitation: true).order('created_at asc')
    unless approvals.blank?
      admins.each do |admin|
        ApprovalPendingMailer.delay.reminder(approvals, admin)
      end
    else
      puts "No Approval"
    end

  end

  desc 'Update cache response if expired'
  task update_cache_response: :environment do
    # puts 'rake update cache response start'

    #create ResponseCache if not exists and api not required any payload validation
    insurers = Insurer.where(status: true).where(activation_status: true)
    #loop for every insurer
    insurers.each do |insurer|
      apis = insurer.insurer_product_apis.where(status:true).where(activation_status: true).where(cache_policy: 'Database').where(payload_validation: nil || '[]')
      next if apis.blank?

      #loop for every insurer product api
      apis.each do |api|

        result = {}

        # check if payload_sha256 exists in ResponseCache table
        response_caches = ResponseCache.where(insurer_product_api_id: api.id).select {|s| s.payload_sha256 == Digest::SHA256.base64digest(api.payload.blank? ? '' : api.payload) && s.url == api.api_url}
        if response_caches.any?

          response_caches.each do |response_cache|
            next unless response_cache.expired_at < Time.now
            # run request
            result = InsurerConnectorController.new.database_request(api, response_cache.request, response_cache, true)
            puts result
          end

        else
          # run new request
          result = InsurerConnectorController.new.database_request(api, api.payload, nil, true)
          puts result

        end

        if !result.blank? && (result[:response_code] == 503 || !result[:response_code].between?(200,209))
          request_body = result[:request_payload]
          response_code = result[:response_code]
          reason = result[:response_code] == 503 ? 'TIME_OUT' : 'REMOTE_SERVER_ERROR'
          response_body = result[:response_body].blank? ? 'nil' : Base64.strict_encode64(result[:response_body].gsub("\n", ''))
          ApiErrorMailer.delay.email(api, request_body, response_code, reason, response_body)
        end


      end

    end

    # update for expired in ResponseCache
    # caches = ResponseCache.all
    # caches.each do |cache|
    #   api = InsurerProductApi.find(cache.insurer_product_api_id)
    #   insurer = api.insurer
    #   # check for valid insurer
    #   next unless insurer.status
    #   next unless insurer.activation_status
    #   # check for valid insurer product api id
    #   next unless api.status
    #   next unless api.activation_status
    #   next unless api.cache_policy == 'Database'
    #   # if check for expired response cache
    #   next unless cache.expired_at < Time.now
    #
    #   # run request
    #   result = InsurerConnectorController.new.database_request(api, cache.request, cache, true)
    #   puts result
    #
    #   if result[:response_code] == 503 || !result[:response_code].between?(200,209)
    #     receiver = insurer
    #     request_body = result[:request_payload]
    #     response_code = result[:response_code]
    #     reason = result[:response_code] == 503 ? 'TIME_OUT' : "REMOTE_SERVER_ERROR"
    #     response_body = result[:response_body].blank? ? 'nil' : Base64.strict_encode64(result[:response_body].gsub("\n", ''))
    #     ApiErrorMailer.delay.email(api, request_body, response_code, reason, response_body)
    #   end
    # end
    #
    # if caches.blank?
    #   puts "no update required"
    # end

  end


end


