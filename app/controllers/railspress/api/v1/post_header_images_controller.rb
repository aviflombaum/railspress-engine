# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostHeaderImagesController < BaseController
        include Railspress::Api::V1::Concerns::PostSerialization

        before_action :ensure_post_images_enabled!
        before_action :set_post

        def show
          return render_error("Header image not found.", status: :not_found) unless @post.header_image.attached?

          render json: {
            data: {
              post_id: @post.id,
              header_image: serialize_header_image(@post),
              header_image_focal_point: serialize_header_image_focal_point(@post)
            }
          }
        end

        def update
          image = header_image_param
          return render_error("Either image or signed_blob_id is required.", status: :unprocessable_content) if image.blank?

          @post.header_image.attach(image)
          render json: { data: serialize_post(@post.reload) }
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
          render_error("Invalid signed blob id.", status: :unprocessable_content)
        end

        def destroy
          @post.header_image.purge if @post.header_image.attached?
          head :no_content
        end

        private

        def ensure_post_images_enabled!
          render_error("Post images are not enabled.", status: :not_found) unless Railspress.post_images_enabled?
        end

        def set_post
          @post = Railspress::Post.find(params[:post_id])
        end

        def header_image_param
          return params[:image] if params[:image].present?
          return if params[:signed_blob_id].blank?

          ActiveStorage::Blob.find_signed!(params[:signed_blob_id])
        end
      end
    end
  end
end
