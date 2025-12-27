Rails.application.routes.draw do
  resources :articles, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]

  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
