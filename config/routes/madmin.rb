# Below are the routes for madmin
namespace :madmin do
  namespace :noticed do
    resources :events
  end
  namespace :noticed do
    resources :notifications
  end
  resources :chats
  resources :documents
  resources :feedbacks
  resources :messages
  resources :models
  resources :sessions
  resources :tool_calls
  resources :users
  root to: "dashboard#show"
end
