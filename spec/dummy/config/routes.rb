Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"

  # Example blog frontend routes
  get "blog", to: "blog#index", as: :blog
  get "blog/search", to: "blog#search", as: :blog_search
  get "blog/category/:slug", to: "blog#category", as: :blog_category
  get "blog/tag/:slug", to: "blog#tag", as: :blog_tag
  get "blog/:slug", to: "blog#show", as: :blog_post

  # CMS demo page
  get "pages", to: "pages#index"

  root 'railspress/admin/dashboard#index'
end
