class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    # TODO: replace with real session lookup
    @current_user ||= User.first
  end

  def require_login
    redirect_to new_session_path, alert: "Please sign in first." unless current_user
  end
end
