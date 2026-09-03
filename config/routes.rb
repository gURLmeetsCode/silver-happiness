Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show"
  get "status" => "status#show"

  root "dashboard#show"

  resource :dashboard, only: :show, controller: "dashboard"
  resource :metrics, only: :show, controller: "metrics"

  resource :goal, only: [ :edit, :update ]
  resource :journal, only: :show

  resources :workout_plans, only: [ :index, :show ]

  resources :daily_logs, only: [ :index, :show, :edit, :update ] do
    member do
      post :copy_meals
      post :add_water
      post :set_water
    end
    resources :meal_entries, only: [ :new, :create, :edit, :update, :destroy ] do
      member do
        post :log_water
      end
    end
    resources :workouts, only: [ :create, :destroy ]
    resources :strength_sessions, except: [ :index ]
    resources :progress_photos, only: [ :create, :destroy ]
    resources :urge_check_ins, only: [ :new, :create ]
  end

  resources :products, only: [ :new, :create ] do
    collection do
      get :lookup_barcode
      post :lookup_barcode
      get :search
      post :search
    end
  end

  resources :grocery_checks, only: [] do
    collection do
      post :toggle
      delete :reset
    end
  end

  resources :recipes, except: [ :destroy ] do
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
  resources :habit_suggestion_feedbacks, only: [ :create ]

  get "today", to: "daily_logs#today"
end
