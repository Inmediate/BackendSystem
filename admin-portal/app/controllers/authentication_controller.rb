class AuthenticationController < ApplicationController
  before_action :authenticate, except: %i[login login_submit logout forgot_password forgot_password_submit reset_password reset_password_submit invite invite_submit]

  def login; end

  def login_submit

    user = User.find_by_email(params[:email])

    if user.nil?
      flash[:error] = 'Sorry, invalid email!'
      redirect_to login_path
      return
    end

    unless user.status
      flash[:error] = 'Sorry, this account has been deleted'
      redirect_to login_path
      return
    end

    unless user.accept_invitation
      flash[:error] = 'Sorry, this account must accept invitation before login'
      redirect_to login_path
      return
    end

    unless user.activation_status
      flash[:error] = 'Sorry, this account has been deactivated'
      redirect_to login_path
      return
    end

    if user.password == params[:password]

      # update previous session status to false
      previous_session = Session.where(user_id: user.id)
      if previous_session.any?
        previous_session.last.update(status: false)
      end

      user_agent = UserAgent.parse(request.user_agent)
      # create session
      user_session = Session.create(
                 user_id: user.id,
                 platform: user_agent.platform,
                 browser: user_agent.browser,
                 ip_address: request.remote_ip,
                 version: user_agent.version,
                 expired_at: Time.now + Setting.find_by_type_name('SESSION_WEB').value.to_i.minutes
      )

      session[:id] = user_session.id
      # session[:user_last_seen] = Time.now
      session[:user_id] = user.id

      redirect_to root_path
      return
    else
      flash[:error] = "Sorry, invalid password!"
      redirect_to login_path
    end
  end

  def logout
    user_session = Session.find(session[:id])

    unless user_session.nil?
      user_session.update(status: false)
      session.delete(:user_id)
      session.delete(:id)
      session.delete(:user_last_seen)
      session.delete(:login_at)
      reset_session
    end

    redirect_to root_path
  end

  def forgot_password; end

  def forgot_password_submit
    user = User.find_by_email(params[:email])

    if user.nil?
      flash[:error] = 'Sorry, invalid email!'
      redirect_to password_forgot_path
      return
    end

    unless user.status
      flash[:error] = 'Sorry, this account has been deleted!'
      redirect_to password_forgot_path
      return
    end

    unless user.accept_invitation
      flash[:error] = 'Sorry, this account must accept invitation first!'
      redirect_to password_forgot_path
      return
    end

    unless user.activation_status
      flash[:error] = 'Sorry, this account has been deactivated!'
      redirect_to password_forgot_path
      return
    end

    user.reset_password
    # send email
    AuthenticationMailer.delay.reseting_password(user, request.base_url)

    flash[:notice] = 'A link has send to your email to reset your password'
    redirect_to password_forgot_path

  end

  def reset_password

    if params[:token].nil?
      redirect_to root_path
      return
    end

    @user = User.find_by(reset_password_token: params[:token])

    if @user.nil?
      redirect_to root_path
      return
    end

    if (@user.reset_password_send_at + 24.hours) < Time.now
      flash[:alert] = 'Reset password token has expired.'
      redirect_to root_path
      return
    end


  end

  def reset_password_submit

    if params[:token].nil?
      redirect_to root_path
      return
    end

    user = User.find_by_reset_password_token(params[:token])

    if user.nil?
      flash[:error] = 'User not exist!'
      redirect_to root_path
      return
    end

    unless user.status
      flash[:error] = 'Sorry, this account has been deleted!'
      redirect_to root_path
      return
    end

    unless user.accept_invitation
      flash[:error] = 'Sorry, this account must accept invitation first!'
      redirect_to root_path
      return
    end

    unless user.activation_status
      flash[:error] = 'Sorry, this account has been deactivated!'
      redirect_to root_path
      return
    end


    if params[:password] != params[:repeat_password]
      flash[:error] = 'Password and Repeat password is not equal!'
      redirect_to "/password/reset/#{user.reset_password_token}"
      return
    end

    user.update(
            password_hash: BCrypt::Password.create(params[:password]),
            reset_password_token: nil,
            reset_password_send_at: nil
    )
    flash[:success] = 'Succesfuly reset your password.'
    redirect_to login_path

  end

  def invite

    @user = User.find_by_invitation_token(params[:token])

    if @user.nil?
      flash[:error] = 'Invalid link'
      redirect_to root_path
      return
    end

    unless @user.status
      flash[:error] = 'Sorry, this account has been deleted'
      redirect_to root_path
      return
    end

    if (@user.invitation_send_at + 24.hours) < Time.now
      flash[:alert] = 'Invitation token has expired.'
      redirect_to root_path
      return
    end

  end

  def invite_submit
    user = User.find_by_invitation_token(params[:token])

    if user.nil?
      flash[:error] = 'Invalid link'
      redirect_to root_path
      return
    end

    if params[:password] != params[:repeat_password]
      flash[:error] = 'Password and Repeat password is not equal!'
      redirect_to "/invite/#{user.invitation_token}"
      return
    end

    user.update(
            name: params[:name],
            password_hash: BCrypt::Password.create(params[:password]),
            activation_status: true,
            accept_invitation: true,
            invitation_token: nil,
            invitation_send_at: nil
    )

    flash[:success] = 'Success create account. Login to proceed'

    unless session[:id].nil?
      redirect_to logout_path
    else
      redirect_to root_path
    end
  end
end
