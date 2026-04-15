# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class TagsController < BaseController
        before_action :set_tag, only: [ :show, :update, :destroy ]

        def index
          tags = Railspress::Tag.ordered
          total_count = tags.count
          tags = tags.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: tags.map { |tag| serialize_tag(tag) },
            meta: {
              page: page,
              per: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          }
        end

        def show
          render json: { data: serialize_tag(@tag) }
        end

        def create
          tag = Railspress::Tag.new(tag_params)

          if tag.save
            render json: { data: serialize_tag(tag) }, status: :created
          else
            render_validation_errors(tag)
          end
        end

        def update
          if @tag.update(tag_params)
            render json: { data: serialize_tag(@tag) }
          else
            render_validation_errors(@tag)
          end
        end

        def destroy
          @tag.destroy
          head :no_content
        end

        private

        def set_tag
          @tag = Railspress::Tag.find(params[:id])
        end

        def tag_params
          params.require(:tag).permit(:name, :slug)
        end

        def page
          [ params.fetch(:page, 1).to_i, 1 ].max
        end

        def per_page
          requested = params.fetch(:per, 20).to_i
          requested = 20 if requested <= 0
          [ requested, 100 ].min
        end

        def serialize_tag(tag)
          {
            id: tag.id,
            name: tag.name,
            slug: tag.slug,
            posts_count: tag.posts.count,
            created_at: tag.created_at,
            updated_at: tag.updated_at
          }
        end
      end
    end
  end
end
