class ApiErrorMailer < ApplicationMailer
  def email(api, request_body, response_code, reason, response_body)
    return if api.nil?
    return if response_code.nil?
    @insurer_api = api
    @receiver = @insurer_api.insurer
    @request_body = request_body
    @response_code = response_code
    @reason = reason
    @response_body = response_body
    mail(to: @receiver.contact_person_email, subject: 'Cron Scheduler: Request Insurer API Failed')
  end
end
