class SessionsController < Devise::SessionsController
  protect_from_forgery except: :create
  
  # Completely override create method for better control
  def create
    # Disable Turbo for this request
    request.env['HTTP_TURBO'] = 'false'
    
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    
    # Force a full page redirect to dashboard (Inicio)
    redirect_to dashboard_path, allow_other_host: false
  end

  private

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end
end 