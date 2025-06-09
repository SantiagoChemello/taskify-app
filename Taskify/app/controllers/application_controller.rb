class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # Redirect users to dashboard (Inicio) page after successful login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  # Redirect users to landing page after logout
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # Disable Turbo for authentication forms to prevent caching issues
  def devise_controller?
    super && request.env['HTTP_TURBO_FRAME'].blank?
  end
end
