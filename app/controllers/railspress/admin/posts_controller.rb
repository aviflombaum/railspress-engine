module Railspress
  module Admin
    class PostsController < BaseController
      before_action :set_post, only: [:show, :edit, :update, :destroy]
      before_action :load_categories, only: [:new, :create, :edit, :update]

      def index
        @sort = params[:sort].presence || "created_at"
        @direction = params[:direction].presence || "desc"

        @posts = Post.includes(:category, :tags)
                     .search(params[:q])
                     .by_category(params[:category_id])
                     .by_status(params[:status])
                     .sorted_by(@sort, @direction)

        @total_count = @posts.count
        @page = [params[:page].to_i, 1].max
        @total_pages = (@total_count.to_f / Post::PER_PAGE).ceil
        @posts = @posts.page(@page)

        @categories = Category.ordered
      end

      def show
      end

      def new
        @post = Post.new
        @post.author = current_author if authors_enabled?
      end

      def create
        @post = Post.new(post_params)
        if @post.save
          redirect_to admin_post_path(@post), notice: "Post created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @post.update(post_params)
          redirect_to admin_post_path(@post), notice: "Post updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @post.destroy
        redirect_to admin_posts_path, notice: "Post deleted."
      end

      private

      def set_post
        @post = Post.find(params[:id])
      end

      def load_categories
        @categories = Category.ordered
      end

      def post_params
        permitted = [
          :title,
          :slug,
          :category_id,
          :content,
          :status,
          :published_at,
          :reading_time,
          :meta_title,
          :meta_description,
          :tag_list
        ]
        permitted << :author_id if authors_enabled?
        if post_images_enabled?
          permitted.push(:header_image, :remove_header_image)
          # Focal point nested attributes
          if Railspress.focal_points_enabled?
            permitted.push(header_image_focal_point_attributes: [:focal_x, :focal_y, :overrides])
          end
        end
        params.require(:post).permit(permitted)
      end
    end
  end
end
