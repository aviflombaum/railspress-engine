# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class CategoriesController < BaseController
        before_action :set_category, only: [ :show, :update, :destroy ]

        def index
          categories = Railspress::Category.ordered
          total_count = categories.count
          categories = categories.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: categories.map { |category| serialize_category(category) },
            meta: {
              page: page,
              per: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          }
        end

        def show
          render json: { data: serialize_category(@category) }
        end

        def create
          category = Railspress::Category.new(category_params)

          if category.save
            render json: { data: serialize_category(category) }, status: :created
          else
            render_validation_errors(category)
          end
        end

        def update
          if @category.update(category_params)
            render json: { data: serialize_category(@category) }
          else
            render_validation_errors(@category)
          end
        end

        def destroy
          if @category.destroy
            head :no_content
          else
            render_validation_errors(@category)
          end
        end

        private

        def set_category
          @category = Railspress::Category.find(params[:id])
        end

        def category_params
          params.require(:category).permit(:name, :slug, :description)
        end

        def page
          [ params.fetch(:page, 1).to_i, 1 ].max
        end

        def per_page
          requested = params.fetch(:per, 20).to_i
          requested = 20 if requested <= 0
          [ requested, 100 ].min
        end

        def serialize_category(category)
          {
            id: category.id,
            name: category.name,
            slug: category.slug,
            description: category.description,
            posts_count: category.posts.count,
            created_at: category.created_at,
            updated_at: category.updated_at
          }
        end
      end
    end
  end
end
