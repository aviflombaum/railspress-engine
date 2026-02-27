class HomeController < ApplicationController
  def index
    @recent_posts = Railspress::Post.published.ordered.limit(3)
    @featured_projects = Project.where(featured: true).ordered.limit(3)
  end
end
