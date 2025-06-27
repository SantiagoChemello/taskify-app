class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    authorize User
    @users = policy_scope(User).includes(:tasks, :assigned_tasks).order(:name)
  end

  def show
    authorize @user
  end

  def new
    @user = User.new
    authorize @user
  end

  def create
    @user = User.new(user_params)
    authorize @user

    if @user.save
      redirect_to users_path, notice: "Usuario '#{@user.name}' creado exitosamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to users_path, notice: "Usuario '#{@user.name}' actualizado exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    name = @user.name
    @user.destroy
    redirect_to users_path, alert: "Usuario '#{name}' eliminado."
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: 'Usuario no encontrado.'
  end

  def user_params
    permitted_params = [:name, :email, :password, :password_confirmation]
    
    # Only admins can change roles
    if current_user&.admin?
      permitted_params << :role
    end
    
    params.require(:user).permit(permitted_params)
  end
end