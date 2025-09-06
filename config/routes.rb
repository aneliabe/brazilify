Rails.application.routes.draw do

  devise_for :users
  root to: "pages#home"

  get "search", to: "pages#search", as: :search
  resources :workers, only: [:index, :show] do
    resources :appointments, only: [:create]
    member do
      get :contact
    end
  end
  resources :categories, only: [:index, :show] do
    get :services, on: :member
  end

  resources :reviews, only: [:create, :update, :destroy]

  resources :appointments, only: [:show] do
    resources :messages, only: [:create]
    member do
      patch :accept
      patch :decline
      post  :propose_time
      patch :accept_proposed
      patch :decline_proposed
    end
  end

  resources :categories, only: [:index] do
    member do
      get :services
    end
  end

  resources :users, only: :show do
    member do
      get "become_worker"
      post :become_worker, action: :activate_worker
      get "worker", to: "users#worker_dashboard"
      get "edit_worker", to: "users#edit_worker"
      patch "update_worker", to: "users#update_worker"
    end
  end

  get "location_hint", to: "locations#hint"

  get "my/appointments", to: "appointments#index", as: :my_appointments
  get "my/requests",     to: redirect("/my/appointments?as=worker&status=pending"), as: :my_requests
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
