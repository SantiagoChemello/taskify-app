Rails.application.routes.draw do
  devise_for :users
  
  # Component previews (development only)
  if Rails.env.development? && defined?(Lookbook)
    mount Lookbook::Engine, at: "/lookbook"
  end
  
  # Dashboard route
  get 'dashboard', to: 'dashboard#index'
  
  resources :tasks, only: [:index, :new, :create, :edit, :update, :destroy, :show] do
    member do
      patch :complete
      patch :assign
    end
    collection do
      post :sync
    end
  end

  resources :statistics, only: [:index]
  
  # User management (admin only)
  resources :users
  
  # Settings routes
  resources :settings, only: [:index, :update] do
    collection do
      patch :update_profile
      patch :update_preferences
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # Redirect authenticated users to dashboard, others to landing page
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end
  
  root "home#index"
end
