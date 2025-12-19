module Railspress
  module Admin
    class TagsController < BaseController
      before_action :set_tag, only: [:edit, :update, :destroy]

      def index
        @tags = Tag.ordered
      end

      def new
        @tag = Tag.new
      end

      def create
        @tag = Tag.new(tag_params)
        if @tag.save
          redirect_to admin_tags_path, notice: "Tag created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @tag.update(tag_params)
          redirect_to admin_tags_path, notice: "Tag updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @tag.destroy
        redirect_to admin_tags_path, notice: "Tag deleted."
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      end

      def tag_params
        params.require(:tag).permit(:name, :slug)
      end
    end
  end
end
