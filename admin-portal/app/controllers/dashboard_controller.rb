class DashboardController < ApplicationController
  before_action :authenticate, except: %i[setup setup_submit]

  def setup
    unless User.first.nil?
      redirect_to root_path
    end
  end

  def setup_submit
    unless params[:password] == params[:repeat_password]
      flash[:warning] = "Password and Repeat Password is not equal."
      redirect_to setup_path
      return false
    end

    password = BCrypt::Password.create(params[:password])
    user = User.create(
      name: params[:name],
      email: params[:email],
      role_id: 1,
      accept_invitation: true,
      activation_status: true,
      password_hash: password
    )

    flash[:success] = "Success create user. Please login to continue."
    redirect_to login_path

  end

  def main
  end

  def setting
    @session_timeout = Setting.find_by_type_name('SESSION_WEB').value
    @session_timeout_purpose = Setting.find_by_type_name('SESSION_WEB').description
    @api_server_url = Setting.find_by_type_name('API_SERVER_URL').value
    @api_server_url_purpose = Setting.find_by_type_name('API_SERVER_URL').description
    add_breadcrumb 'Global Setting'
  end

  def setting_submit

    if params[:session_timeout].blank? || params[:session_timeout] == '0'
      flash[:error] = 'Session Timeout cannot be empty or 0'
      setting
      @session_timeout = params[:session_timeout]
      @api_server_url = params[:api_url]

      render :setting
      return
    end

    session_timeout = Setting.find_by_type_name('SESSION_WEB')
    api_server_url = Setting.find_by_type_name('API_SERVER_URL')

    session_timeout.update(value: params[:session_timeout])
    api_server_url.update(value: params[:api_url])

    flash[:success] = "Setting updated"
    redirect_to setting_path

  end

  def profile
    @user = current_user
    @sessions = Session.where(user_id: @user.id)
    add_breadcrumb 'User profile'
  end

  def profile_submit
    user = current_user

    if params[:password].blank?
      user.update(name: params[:name])
    else
      if params[:password] != params[:repeat_password]
        flash[:error] = 'Password and Repeat Password not equal'
        redirect_to profile_path
        return
      else
        user.update(name: params[:name], password_hash: BCrypt::Password.create(params[:password]))
      end
    end

    unless user.save
      flash[:error] = 'Somethings wrong, Please try again.'
      redirect_to profile_path
      return
    end

    flash[:success] = 'User Profile updated'
    redirect_to profile_path
  end

end
