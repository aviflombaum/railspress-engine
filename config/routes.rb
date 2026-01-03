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

    # Dynamic entity routes for host-defined CMS models
    scope "entities" do
      scope ":entity_type", constraints: ->(req) { Railspress.entity_registered?(req.params[:entity_type]) } do
        get "/", to: "entities#index", as: :entity_index
        get "/new", to: "entities#new", as: :new_entity
        post "/", to: "entities#create"
        get "/:id", to: "entities#show", as: :entity
        get "/:id/edit", to: "entities#edit", as: :edit_entity
        patch "/:id", to: "entities#update"
        put "/:id", to: "entities#update"
        delete "/:id", to: "entities#destroy"
      end
    end
  end
end
