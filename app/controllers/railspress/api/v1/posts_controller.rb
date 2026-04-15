# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostsController < BaseController
        include Railspress::Api::V1::Concerns::PostSerialization

        before_action :set_post, only: [ :show, :update, :destroy ]

        def index
          posts = Railspress::Post.includes(:category, :tags).sorted_by(sort_column, sort_direction)
          total_count = posts.count

          posts = posts.offset((page - 1) * per_page).limit(per_page)

          render json: {
            data: posts.map { |post| serialize_post(post) },
            meta: {
              page: page,
              per: per_page,
              total_count: total_count,
              total_pages: (total_count.to_f / per_page).ceil
            }
          }
        end

        def show
          render json: { data: serialize_post(@post) }
        end

        def create
          post = Railspress::Post.new(post_params.except(:header_image_signed_blob_id))
          attach_header_image_from_signed_blob(post, post_params[:header_image_signed_blob_id])

          if post.save
            render json: { data: serialize_post(post) }, status: :created
          else
            render_validation_errors(post)
          end
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
          post.errors.add(:header_image, "signed blob id is invalid")
          render_validation_errors(post)
        end

        def update
          @post.assign_attributes(post_params.except(:header_image_signed_blob_id))
          attach_header_image_from_signed_blob(@post, post_params[:header_image_signed_blob_id])

          if @post.save
            render json: { data: serialize_post(@post) }
          else
            render_validation_errors(@post)
          end
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
          @post.errors.add(:header_image, "signed blob id is invalid")
          render_validation_errors(@post)
        end

        def destroy
          @post.destroy
          head :no_content
        end

        private

        def set_post
          @post = Railspress::Post.find(params[:id])
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

          permitted << :author_id if Railspress.authors_enabled?

          if Railspress.post_images_enabled?
            permitted << :header_image
            permitted << :header_image_signed_blob_id
            permitted << :remove_header_image

            if Railspress.focal_points_enabled?
              permitted << { header_image_focal_point_attributes: [ :focal_x, :focal_y, { overrides: {} } ] }
            end
          end

          params.require(:post).permit(*permitted)
        end

        def page
          [ params.fetch(:page, 1).to_i, 1 ].max
        end

        def per_page
          requested = params.fetch(:per, Railspress::Post.per_page_count).to_i
          requested = Railspress::Post.per_page_count if requested <= 0
          [ requested, 100 ].min
        end

        def sort_column
          params[:sort].presence || "created_at"
        end

        def sort_direction
          params[:direction].presence || "desc"
        end

        def attach_header_image_from_signed_blob(post, signed_blob_id)
          return if signed_blob_id.blank?
          return unless Railspress.post_images_enabled?

          post.header_image.attach(ActiveStorage::Blob.find_signed!(signed_blob_id))
        end
      end
    end
  end
end
