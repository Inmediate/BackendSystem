class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # before_action :set_url
  before_action :authenticate
  helper_method :current_user, :is_super_admin, :is_admin, :is_editor, :redirect_not_admin, :can_approve_reject_deactivate, :redirect_cannot_delete
  add_breadcrumb 'Home', :root_path


  def authenticate

    if session[:user_id].nil?
      redirect_to login_path
      return false
    end

    # check if user exists
    if check_user.nil?
      redirect_to login_path
      return false
    else
      # if user is deactivated
      unless User.find(session[:user_id]).activation_status
        redirect_to logout_path
        return false
      end

      # if user is deleted
      unless User.find(session[:user_id]).status
        redirect_to logout_path
        return false
      end
    end

    # if session already expired
    if Session.find(session[:id]).expired_at < Time.now
      redirect_to logout_path
      return false
    end


    # check if user log in other device
    unless Session.find(session[:id]).status
      redirect_to logout_path
      return false
    end


    # session[:user_last_seen] = Time.now

  end

  def check_user
    if session[:user_id].blank?
      @check_user = nil
      return
    end
    begin
      @check_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
    rescue ActiveRecord::RecordNotFound
      session[:user_id] = ''
    end
  end


  private

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find(session[:user_id])
  end

  def is_super_admin
    if current_user.role.id == 1
      return true
    end

    return false
  end

  def is_admin
    if current_user.role.id == 2
      return true
    end

    return false
  end

  def is_editor
    if current_user.role.id == 3
      return true
    end

    return false
  end


  def can_approve_reject_deactivate
    if is_super_admin || is_admin
      return true
    end
    return false
  end

  def redirect_not_admin
    if !is_admin && !is_super_admin
      redirect_to root_path
    end
  end

  def redirect_cannot_delete
    if !is_super_admin
      redirect_to root_path
    end
  end

  # def set_url
  #   ActionMailer::Base.default_url_options[:host]  = request.base_url
  #   puts "ActionMailer::Base.default_url_options[:host] #{ActionMailer::Base.default_url_options[:host]}"
  # end


end
