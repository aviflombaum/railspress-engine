module Railspress
  module Admin
    class DashboardController < BaseController
      def index
        @posts_count = Post.count
        @categories_count = Category.count
        @tags_count = Tag.count
        @recent_posts = Post.ordered.limit(5)
      end
    end
  end
end
