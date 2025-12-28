Rails.application.routes.draw do
  resources :articles, only: [ :index, :show ]

  # 認証は不要になったため無効化（将来的に必要になったら復活させる）
  # resource :session
  # resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check

  root "articles#index"
end
