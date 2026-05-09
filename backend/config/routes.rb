Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :employees
      get "insights/countries", to: "insights#countries"
      get "insights",           to: "insights#index"
    end
  end
end
