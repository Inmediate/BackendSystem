class UserMailer < ApplicationMailer
  def deactivated(user)
    return if user.nil?
    @user = user
    return if @user.activation_status
    mail(to: @user.email, subject: 'Insurance Market API Portal account: Deactivated')
  end

  def deleted(user)
    return if user.nil?
    @user = user
    return if @user.status
    mail(to: @user.email, subject: 'Insurance Market API Portal account: Deleted')
  end
end
