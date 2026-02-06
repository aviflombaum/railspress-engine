module Railspress
  module Admin
    class DashboardController < BaseController
      def index
        @posts_count = Post.count
        @categories_count = Category.count
        @tags_count = Tag.count
        @content_groups_count = ContentGroup.active.count
        @content_elements_count = ContentElement.active.count
        @recent_posts = Post.ordered.limit(5)
        @recent_content_elements = ContentElement.active.includes(:content_group).order(updated_at: :desc).limit(5)
      end
    end
  end
end
