class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pundit for authorization
  include ::Pundit::Authorization

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?


  protected

  # Pundit helper method for task assignment checking
  def can_assign_task?(task)
    return false unless current_user.present?
    policy(task).assign?
  end
  helper_method :can_assign_task?

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :role ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # Redirect users to dashboard (Inicio) page after successful login
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  # Redirect users to landing page after logout
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # Override devise_controller? for better detection
  def devise_controller?
    is_a?(Devise::SessionsController) ||
    is_a?(Devise::RegistrationsController) ||
    is_a?(Devise::PasswordsController) ||
    is_a?(Devise::ConfirmationsController) ||
    is_a?(Devise::UnlocksController) ||
    self.class.name.include?("Devise") ||
    defined?(super) && super
  end

  private

  # Handle Pundit authorization failures
  def user_not_authorized
    flash[:alert] = "No tienes permisos para realizar esta acción."
    redirect_back(fallback_location: dashboard_path)
  end

  # Rescue Pundit authorization failures
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized



  # Only verify Pundit for our main application controllers
  def should_verify_pundit?
    !devise_controller? &&
    !controller_name.include?("devise") &&
    !self.class.name.include?("Devise") &&
    controller_name.in?([ "tasks", "users" ]) &&
    user_signed_in?
  end
end
