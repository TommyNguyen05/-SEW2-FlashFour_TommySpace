class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    # To allow 'display_name' to be accepted during the sign-up process.
    devise_parameter_sanitizer.permit(:sign_up, keys: [:display_name])
  end
  # --- END OF NEW LINES ---
end