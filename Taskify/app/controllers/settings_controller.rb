class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end

  def update_profile
    @user = current_user

    if @user.update(profile_params)
      redirect_to settings_path, notice: "Perfil actualizado exitosamente."
    else
      redirect_to settings_path, alert: "Error al actualizar el perfil."
    end
  end

  def update_preferences
    @user = current_user

    if @user.update(preferences_params)
      redirect_to settings_path, notice: "Preferencias actualizadas exitosamente."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :first_name, :last_name)
  end

  def preferences_params
    # For now, we'll just handle basic preferences
    # You can extend this later with actual preference fields
    params.require(:user).permit()
  end
end
