class AuthenticationMailer < ApplicationMailer
  def user_invitation(user, url)
    return if user.nil?
    return if url.blank?
    @user = user
    @url = "#{url}/invite/#{@user.invitation_token}"
    return if @user.invitation_token.nil?
    mail(to: @user.email, subject: 'Insurance Market API Portal: Account Invitation')
  end

  def reseting_password(user, url)
    return if user.nil?
    return if url.blank?
    @user = user
    @url = "#{url}/password/reset/#{user.reset_password_token}"
    return if @user.reset_password_token.nil?
    mail(to: @user.email, subject: 'Insurance Market API Portal account: Reset Password')
  end
end
