class LogController < ApplicationController

  add_breadcrumb 'Reports'

  def product_api
    add_breadcrumb 'Insurer Product APIs'

    respond_to do |format|
      format.json do

        puts "params[:viewAll]: #{params[:viewAll]}"

        start_date = params[:dateRange].split.first.to_date.beginning_of_day
        to_date = params[:dateRange].split.last.to_date.end_of_day

        puts "seach #{params[:search][:value]}"

        data = InsurerProductApiReport.where(created_at: start_date..to_date).order('created_at desc')
        data_search = InsurerApiLogFilter.new.filter(data, params[:search][:value])
        api_logs = params[:search][:value].blank? ? data.page(1).per(params[:length].to_i).padding(params[:start].to_i) : data_search.page(1).per(params[:length].to_i).padding(params[:start].to_i)

        result = {}

        result[:draw] = params[:draw].to_i
        result[:recordsTotal] = params[:search][:value].blank? ? data.count : data_search.count
        result[:recordsFiltered] = result[:recordsTotal]

        if !params[:viewAll].blank? && params[:viewAll] == 'true' && params[:search][:value].blank?
          data = InsurerProductApiReport.all.order('created_at desc')
          api_logs = data.page(1).per(params[:length].to_i).padding(params[:start].to_i)

          result[:recordsTotal] = data.count
          result[:recordsFiltered] = result[:recordsTotal]
        end



        api_logs_array = []

        api_logs.each do |api_log|
          api_log_array = []

          #request payload
          rq_payload = if accept_type(api_log.request_payload) == 'XML'
                         api_log.request_payload.nil? ? '' : Nokogiri::XML(api_log.request_payload)
                       else
                         api_log.request_payload.nil? ? '' : JSON.pretty_generate(JSON.parse(api_log.request_payload))
                       end

          #response payload

          rpsn_payload = ''
          if api_log.source == "Database"
            rpsn_payload = api_log.response_payload
          else
            if accept_type(api_log.response_payload) == 'XML'
              rpsn_payload = api_log.response_payload.nil? ? '' : Nokogiri::XML(api_log.response_payload)
            else
              rpsn_payload = api_log.response_payload.nil? ? '' : JSON.pretty_generate(JSON.parse(api_log.response_payload))
            end
          end

          api_log_array << api_log.created_at.strftime('%d/%m/%Y %H:%M:%S')
          api_log_array << api_log.insurer_product_api_id
          api_log_array << api_log.request_id
          api_log_array << api_log.source
          api_log_array << api_log.request_url
          api_log_array << api_log.request_method
          api_log_array << api_log.response_code
          api_log_array << rq_payload
          api_log_array << rpsn_payload
          api_logs_array << api_log_array
        end

        result[:data] = api_logs_array

        puts "result #{result.to_json}"

        render json: result.to_json

      end
      format.html do
        # @list = InsurerProductApiReport.where('created_at > ?', 1.month.ago).order('created_at desc')
        @startDate = Time.now.months_ago(1)
        @endDate = Time.now
      end
    end

  end

  def client_api

    respond_to do |format|
      format.json do

        puts "params[:viewAll]: #{params[:viewAll]}"

        start_date = params[:dateRange].split.first.to_date.beginning_of_day
        to_date = params[:dateRange].split.last.to_date.end_of_day

        puts "seach #{params[:search][:value]}"

        data = ClientApiReport.where(created_at: start_date..to_date).order('created_at desc')
        data_search = ClientApiLogFilter.new.filter(data, params[:search][:value])
        api_logs = params[:search][:value].blank? ? data.page(1).per(params[:length].to_i).padding(params[:start].to_i) : data_search.page(1).per(params[:length].to_i).padding(params[:start].to_i)

        result = {}

        result[:draw] = params[:draw].to_i
        result[:recordsTotal] = params[:search][:value].blank? ? data.count : data_search.count
        result[:recordsFiltered] = result[:recordsTotal]

        if !params[:viewAll].blank? && params[:viewAll] == 'true' && params[:search][:value].blank?
          data = ClientApiReport.all.order('created_at desc')
          api_logs = data.page(1).per(params[:length].to_i).padding(params[:start].to_i)

          result[:recordsTotal] = data.count
          result[:recordsFiltered] = result[:recordsTotal]
        end



        api_logs_array = []

        api_logs.each do |api_log|
          api_log_array = []

          #request payload
          rq_payload = api_log.request_payload.nil? ? '' : JSON.pretty_generate(JSON.parse(api_log.request_payload))

          #response payload
          rpsn_payload = if api_log.request_format == 'application/xml'
                           api_log.response_payload.nil? ? '' : Nokogiri::XML(api_log.response_payload)
                         else
                           api_log.response_payload.nil? ? '' : JSON.pretty_generate(JSON.parse(api_log.response_payload))
                         end

          api_log_array << api_log.created_at.strftime('%d/%m/%Y %H:%M:%S')
          api_log_array << api_log.client_id
          api_log_array << api_log.client_api_key
          api_log_array << api_log.client_api_id
          api_log_array << api_log.request_ip
          api_log_array << api_log.request_endpoint
          api_log_array << api_log.request_method
          api_log_array << api_log.response_code
          api_log_array << rq_payload
          api_log_array << rpsn_payload
          api_logs_array << api_log_array
        end

        result[:data] = api_logs_array

        puts "result #{result.to_json}"

        render json: result.to_json

      end
      format.html do
        # @list = InsurerProductApiReport.where('created_at > ?', 1.month.ago).order('created_at desc')
        @startDate = Time.now.months_ago(1)
        @endDate = Time.now
      end
    end

    add_breadcrumb 'Client APIs'
  end

  def approval

    add_breadcrumb 'Approval'

    respond_to do |format|
      format.json do

        puts "params[:viewAll]: #{params[:viewAll]}"

        start_date = params[:dateRange].split.first.to_date.beginning_of_day
        to_date = params[:dateRange].split.last.to_date.end_of_day

        puts "seach #{params[:search][:value]}"

        data = Audited.audit_class.where(created_at: start_date..to_date).order('id desc')

        # data_search = Audited.audit_class.joins('left join users on users.id = user_id').where(created_at: start_date..to_date).where("action like ?", "%#{params[:search][:value]}%").where("auditable_type like ?", "%#{params[:search][:value]}%").where("auditable_id like ?", "%#{params[:search][:value]}%").where("users.name like ?", "%#{params[:search][:value]}%").where("users.email like ?", "%#{params[:search][:value]}%").order('id desc')
        data_search = Audited.audit_class.joins('left join users on users.id = user_id').where(created_at: start_date..to_date).where("CONCAT(action, auditable_type, auditable_id, audited_changes, '', users.name, users.email) LIKE ?", "%#{params[:search][:value]}%").order('id desc')
        audit_logs = params[:search][:value].blank? ? data.page(1).per(params[:length].to_i).padding(params[:start].to_i) : data_search.page(1).per(params[:length].to_i).padding(params[:start].to_i)
        # audit_logs = data.page(1).per(params[:length].to_i).padding(params[:start].to_i)

        result = {}

        result[:draw] = params[:draw].to_i
        result[:recordsTotal] = params[:search][:value].blank? ? data.count : data_search.count
        result[:recordsFiltered] = result[:recordsTotal]

        if !params[:viewAll].blank? && params[:viewAll] == 'true' && params[:search][:value].blank?
          data = Audited.audit_class.order('id desc')
          audit_logs = data.page(1).per(params[:length].to_i).padding(params[:start].to_i)

          result[:recordsTotal] = data.count
          result[:recordsFiltered] = result[:recordsTotal]
        end

        approval_logs = []
        audit_logs.each do |log|
          log_hash = {}
          log_hash[:id] = log.id
          log_hash[:timestamp] = log.created_at.strftime('%d/%m/%Y %H:%M:%S')
          log_hash[:action] = log.action
          log_hash[:item] = "#{log.auditable_type} :#{log.auditable_id}"
          log_hash[:user] = log.user_id

          if log.action == 'update'
            new_values_array = []
            old_values_array = []
            log.audited_changes.each do |key, array|
              new_values_array << "#{key}: #{array.last}"
              old_values_array << "#{key}: #{array.first}"
            end

            log_hash[:old_values] = old_values_array
            log_hash[:new_values] = new_values_array
          else
            new_values_array = []
            log.audited_changes.each do |key, array|
              new_values_array << "#{key}: #{array}"
            end
            log_hash[:old_values] = nil
            log_hash[:new_values] = new_values_array
          end
          approval_logs << log_hash
        end

        approval_logs_array = []

        approval_logs.each do |approval_log|
          approval_log_array = []

          #new value & old value
          new_value = ''
          approval_log[:new_values].each {|s| new_value << "#{s}\n"}
          old_value = ''
          if approval_log[:action] == 'update'
            approval_log[:old_values].each {|s| old_value << "#{s}\n"}
          else
            old_value = approval_log[:old_values]
          end

          #user
          user = ''
          if User.where(id: approval_log[:user]).any?
            user = "#{User.find(approval_log[:user]).name}\n#{User.find(approval_log[:user]).email}"
          end

          approval_log_array << approval_log[:timestamp]
          approval_log_array << approval_log[:action]
          approval_log_array << approval_log[:item]
          approval_log_array << "<td style='word-wrap:break-word;'>#{new_value}</td>".html_safe
          approval_log_array << old_value
          approval_log_array << user
          approval_logs_array << approval_log_array
        end

        result[:data] = approval_logs_array

        puts "result #{result.to_json}"

        render json: result.to_json

      end
      format.html do
        @startDate = Time.now.months_ago(1)
        @endDate = Time.now
      end
    end


  end

  def session_history

    add_breadcrumb 'Session History'

    respond_to do |format|
      format.json do

        puts "params[:viewAll]: #{params[:viewAll]}"

        start_date = params[:dateRange].split.first.to_date.beginning_of_day
        to_date = params[:dateRange].split.last.to_date.end_of_day

        puts "seach #{params[:search][:value]}"

        data = Session.where(created_at: start_date..to_date).order('created_at desc')
        data_search = SessionLogFilter.new.filter(data, params[:search][:value])
        session_logs = params[:search][:value].blank? ? data.page(1).per(params[:length].to_i).padding(params[:start].to_i) : data_search.page(1).per(params[:length].to_i).padding(params[:start].to_i)

        result = {}

        result[:draw] = params[:draw].to_i
        result[:recordsTotal] = params[:search][:value].blank? ? data.count : data_search.count
        result[:recordsFiltered] = result[:recordsTotal]

        if !params[:viewAll].blank? && params[:viewAll] == 'true' && params[:search][:value].blank?
          data = Session.all.order('created_at desc')
          session_logs = data.page(1).per(params[:length].to_i).padding(params[:start].to_i)

          result[:recordsTotal] = data.count
          result[:recordsFiltered] = result[:recordsTotal]
        end



        session_logs_array = []

        session_logs.each do |session_log|
          session_log_array = []
          session_log_array << session_log.created_at.strftime('%d/%m/%Y %H:%M:%S')
          session_log_array << session_log.expired_at.strftime('%d/%m/%Y %H:%M:%S')
          session_log_array << session_log.user_id
          session_log_array << "#{User.where(id: session_log.user_id).blank? ? '' : User.find(session_log.user_id).name}"
          session_log_array << session_log.ip_address
          session_log_array << session_log.platform
          session_log_array << session_log.browser
          session_logs_array << session_log_array
        end

        result[:data] = session_logs_array

        puts "result #{result.to_json}"

        render json: result.to_json

      end
      format.html do
        @startDate = Time.now.months_ago(1)
        @endDate = Time.now
      end
    end

  end

  private

  def accept_type(body)
    JSON.parse(body)
    return 'JSON'
  rescue
    return 'XML'
  end

end
