Rails.application.routes.draw do

  devise_for :users
  root to: "pages#home"

  get "search", to: "pages#search", as: :search
  resources :workers, only: [:index, :show] do
    member do
      get :contact
    end
  end
  resources :categories, only: [:index]

  resources :users, only: :show do
    member do
      get "become_worker"
      post :become_worker, action: :activate_worker
      get "worker", to: "users#worker_dashboard"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
