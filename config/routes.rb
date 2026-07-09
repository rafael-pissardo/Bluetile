Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health", to: "health#show"
  get "health/deep", to: "health#deep"

  namespace :v1 do
    post "user/check_status", to: "user/check_status#create"
  end
end
