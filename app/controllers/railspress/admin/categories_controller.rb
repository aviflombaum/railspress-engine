module Railspress
  module Admin
    class CategoriesController < BaseController
      before_action :set_category, only: [:edit, :update, :destroy]

      def index
        @categories = Category.ordered
      end

      def new
        @category = Category.new
      end

      def create
        @category = Category.new(category_params)
        if @category.save
          redirect_to admin_categories_path, notice: "Category created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @category.update(category_params)
          redirect_to admin_categories_path, notice: "Category updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @category.destroy
          redirect_to admin_categories_path, notice: "Category deleted."
        else
          redirect_to admin_categories_path, alert: "Cannot delete category with posts."
        end
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name, :slug, :description)
      end
    end
  end
end
