class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end

Rails.application.routes.draw do
  # ... other routes
  get "profile" => "users#show", as: :profile # Adds a /profile URL
  # ...
end
