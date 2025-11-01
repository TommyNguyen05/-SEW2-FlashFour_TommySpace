Rails.application.routes.draw do
  resources :users, only: [:new, :create, :show]
  resource  :session, only: [:new, :create, :destroy]

  resources :decks do
    resources :cards do
      resources :reviews, only: [:create]
      resource :card_progress, only: [:show, :update]
    end
    resources :deck_collaborators, only: [:index, :create, :destroy]
  end

  resources :tags, only: [:index, :create]
  resources :taggings, only: [:create, :destroy]

  get "progress", to: "progress#index", as: :progress

  root "decks#index"
end
