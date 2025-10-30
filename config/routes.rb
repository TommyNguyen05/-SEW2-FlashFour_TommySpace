Rails.application.routes.draw do
  # This line creates all the necessary routes for user accounts (sign up, sign in, etc.)
  devise_for :users

  # This sets your home page
  root 'decks#index'

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Your other routes
  resources :decks do
    resources :flashcards, only: [:new, :create]
  end
end