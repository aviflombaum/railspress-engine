Railspress::Engine.routes.draw do
  namespace :admin do
    root "dashboard#index"
    resources :categories, except: [:show]
    resources :tags, except: [:show]
    resources :posts
  end
end
