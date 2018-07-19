class ClientMailer < ApplicationMailer
  def create(client)
    return if client.nil?
    @client = client
    return if @client.client_api_key.nil?
    @api_url = Setting.find_by_type_name('API_SERVER_URL').value
    mail(to: @client.contact_person_email, subject: 'Insurance Market API Portal: Client Account Approved')
  end

  def deactivated(client)
    return if client.nil?
    @client = client
    mail(to: @client.contact_person_email, subject: 'Insurance Market API Portal: Client Account Deactivated')
  end

  def deleted(client)
    return if client.nil?
    @client = client
    mail(to: @client.contact_person_email, subject: 'Insurance Market API Portal: Client Account Deleted')
  end
end
