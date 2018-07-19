class InsurerMailer < ApplicationMailer

  def create(insurer)
    return if insurer.nil?
    @insurer = insurer
    mail(to: @insurer.contact_person_email, subject: 'Insurance Market API Portal: Client Account Approved')
  end

  # def deactivated(client)
  #   return if client.nil?
  #   @client = client
  #   mail(to: @client.contact_person_email, subject: 'Insurance Market API Portal: Client Account Deactivated')
  # end
  #
  # def deleted(client)
  #   return if client.nil?
  #   @client = client
  #   mail(to: @client.contact_person_email, subject: 'Insurance Market API Portal: Client Account Deleted')
  # end
end
