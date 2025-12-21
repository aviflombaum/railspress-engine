module Railspress
  module Admin
    class PostsController < BaseController
      before_action :set_post, only: [:show, :edit, :update, :destroy]
      before_action :load_categories, only: [:new, :create, :edit, :update]

      def index
        @posts = Post.includes(:category, :tags).ordered
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
          :meta_title,
          :meta_description,
          :tag_list
        ]
        permitted << :author_id if authors_enabled?
        permitted.push(:header_image, :remove_header_image) if header_images_enabled?
        params.require(:post).permit(permitted)
      end
    end
  end
end
