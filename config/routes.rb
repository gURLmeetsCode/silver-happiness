Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#show"

  resource :dashboard, only: :show, controller: "dashboard"

  resource :goal, only: [ :edit, :update ]

  resources :workout_plans, only: [ :index, :show ]

  resources :daily_logs do
    member do
      post :copy_meals
      post :add_water
      post :set_water
    end
    resources :meal_entries, only: [ :create, :destroy ] do
      member do
        post :log_water
      end
    end
    resources :workouts, only: [ :create, :destroy ]
    resources :strength_sessions
    resources :progress_photos, only: [ :create, :destroy ]
  end

  resources :products, only: [ :new, :create ]

  resources :recipes do
    collection do
      get :grocery
    end
    member do
      patch :react
      patch :archive
      patch :tired_of
      patch :restore
    end
  end

  resources :outfit_photos, only: [ :index, :new, :create, :destroy ]

  get "today", to: "daily_logs#today"
end
