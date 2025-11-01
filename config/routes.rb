Rails.application.routes.draw do
  # This line creates all the necessary routes for user accounts (sign up, sign in, etc.)
  devise_for :users

  # This sets your home page
  root 'decks#index'

  # Health check route
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Progress analytics route
  get 'progress', to: 'card_progresses#index', as: :progress

  # Your other routes
  resources :decks do
    resources :flashcards, only: %i[new create]

    # Learning session routes
    resource :learning_session, only: [] do
      get 'start', to: 'learning_sessions#start', as: 'start'
      get 'show', to: 'learning_sessions#show', as: ''
      post 'rate', to: 'learning_sessions#rate', as: 'rate'
      get 'complete', to: 'learning_sessions#complete', as: 'complete'
      post 'restart', to: 'learning_sessions#restart', as: 'restart'
    end
  end
end
