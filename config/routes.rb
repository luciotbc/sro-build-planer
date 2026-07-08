Rails.application.routes.draw do
  resources :characters do
    resources :character_skills, only: [:update], param: :skill_group_id
    resources :character_masteries, only: [:update], param: :mastery_id
    member do
      post :max_mastery, to: "bulk_skill_actions#max_mastery"
      post :max_skills, to: "bulk_skill_actions#max_skills"
      post :clear_mastery, to: "bulk_skill_actions#clear_mastery"
    end
  end
  # Public, read-only shared build page (docs/todo/021, spec 05).
  get "shared/:share_token" => "shared_builds#show", :as => :shared_build

  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[new create]
  # Account settings page (docs/todo/022, spec 09).
  resource :settings, only: :show
  namespace :settings do
    resource :email, only: :update
    resource :password, only: :update
  end
  get "email_confirmation/:token" => "email_confirmations#show",
      :as => :email_confirmation
  post "email_confirmation/resend" => "email_confirmations#resend",
       :as => :resend_email_confirmation
  root "home#index"

  # Living design system documentation - development only.
  get "docs/design_system" => "docs#design_system" if Rails.env.development?

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
