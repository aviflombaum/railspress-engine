Railspress::Engine.routes.draw do
  root to: redirect("admin")
  namespace :admin do
    root "dashboard#index"
    resources :categories, except: [ :show ]
    resources :tags, except: [ :show ]

    # Content Element CMS
    resources :content_groups
    resources :content_elements do
      member do
        get :inline
      end
    end
    resources :content_element_versions, only: [:show]

    # CMS Content Transfer (export/import)
    resource :cms_transfer, only: [:show] do
      post :export, on: :member
      post :import, on: :member
    end

    resources :posts do
      member do
        get "image_editor/:attachment", action: :image_editor, as: :image_editor
      end
    end

    # Standalone focal point updates (works outside parent form)
    resources :focal_points, only: [:update]
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

    # UI/UX Prototypes (development only)
    resources :prototypes, only: [] do
      collection do
        get :image_section
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
        get "/:id/image_editor/:attachment", to: "entities#image_editor", as: :entity_image_editor
        patch "/:id", to: "entities#update"
        put "/:id", to: "entities#update"
        delete "/:id", to: "entities#destroy"
      end
    end
  end
end
