class UserController < ApplicationController

  before_action :redirect_not_admin, except: %i[list]
  before_action :redirect_cannot_delete, only: %i[delete]

  add_breadcrumb 'User Accounts', :user_list_path

  def list
    @users = User.where(status: true).order('created_at desc')
  end

  def new
    @user = User.new
    add_breadcrumb 'New'
  end

  def create

    user = User.find_by_email(params[:user]['email'])

    if user.nil?
      user = User.create(user_params)
    else
      unless user.status
        # reinvite user deleted
        user.update(name: params[:user]['name'], role_id: params[:user]['role_id'], accept_invitation: false, activation_status: false , status: true)
      else
        if  user.activation_status
          # abort invitation
          flash[:error] = 'User already exists and activated.'
          redirect_to user_list_path
          return
        else
          # reinvite again
          user.update(name: params[:user]['name'], role_id: params[:user]['role_id'], accept_invitation: false)
        end
      end
    end

    unless user.save
      flash[:error] = 'Somethings wrong. Please try again.'
      redirect_to user_new_path
      return
    end

    user.invitation
    # send email invitation
    AuthenticationMailer.delay.user_invitation(user, request.base_url)
    flash[:success] = 'Successful send invitation'
    redirect_to user_list_path

  end

  def edit
    @user = User.find(params[:id])
    add_breadcrumb @user.name
  end

  def update
    user = User.find(params[:id])
    user.update(user_params)
    if !user.save
      flash[:error] = "Failed to update User account."
    else
      flash[:success] = "User account updated."
    end

    # if accunt is deactivated
    unless user.activation_status
      UserMailer.delay.deactivated(user)
    end

    redirect_to "/user/edit/#{user.id}"
  end

  def delete
    user = User.find(params[:id])

    if user.role.id == 1
      redirect_to root_path
      return
    end

    user.update(status: false)

    unless user.save
      flash[:error] = 'Failed to delete user account'
      redirect_to "/user/edit/#{user.id}"
      return
    end

    unless user.status
      UserMailer.delay.deleted(user)
    end

    flash[:success] = 'Success delete user account'
    redirect_to user_list_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :role_id, :activation_status)
  end

end
