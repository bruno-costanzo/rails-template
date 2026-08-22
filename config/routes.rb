Rails.application.routes.draw do
  resources :chats, except: [ :edit, :update ] do
    resources :messages, only: [ :create ]
  end
  resource :support_chat, only: [ :show ] do
    resource :photos, only: [ :create ], controller: "support_chat_photos"
  end
  resources :documents
  resources :models, only: [ :index, :show ] do
    collection do
      post :refresh
    end
  end
  resource :session
  resource :registration, only: %i[new create]
  resource :profile, only: %i[edit update]
  resources :passwords, param: :token
  resource :feedback, only: %i[new create]
  get "feedback/photos/:signed_id", to: "feedback_photos#show", as: :feedback_photo

  namespace :admin do
    resources :feedbacks, only: [ :index ] do
      member do
        patch :resolve
      end
    end
  end

  mount SolidErrors::Engine => "/errors"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
