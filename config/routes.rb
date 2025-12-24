Railspress::Engine.routes.draw do
  root to: redirect("admin")
  namespace :admin do
    root "dashboard#index"
    resources :categories, except: [ :show ]
    resources :tags, except: [ :show ]
    resources :posts
    resources :imports, only: [:create] do
      collection do
        get ":type", action: :show, as: :typed
      end
    end
    resources :exports, only: [:create] do
      collection do
        get ":type", action: :show, as: :typed
      end
      member do
        get :download
      end
    end
  end
end
