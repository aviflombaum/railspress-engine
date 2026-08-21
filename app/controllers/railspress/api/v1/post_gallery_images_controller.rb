# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostGalleryImagesController < BaseController
        include Railspress::Api::V1::Concerns::PostSerialization

        ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

        before_action :ensure_post_images_enabled!
        before_action :set_post
        before_action :set_gallery_image, only: :destroy

        def index
          render json: { data: serialize_gallery_images(@post) }
        end

        def create
          source = gallery_image_source
          return render_error("Invalid signed blob id.", status: :unprocessable_content) if source&.key?(:invalid)
          return render_error("Either image or signed_blob_id is required.", status: :unprocessable_content) unless source

          unless ALLOWED_CONTENT_TYPES.include?(source[:content_type])
            return render_error("Unsupported image type. Allowed: JPEG, PNG, GIF, WebP.", status: :unprocessable_content)
          end

          @post.gallery_images.attach(source[:attachable])
          attachment = @post.gallery_images.attachments.order(:id).last

          render json: { data: serialize_gallery_image(attachment) }, status: :created
        end

        def destroy
          @gallery_image.purge
          head :no_content
        end

        private

        def ensure_post_images_enabled!
          render_error("Post images are not enabled.", status: :not_found) unless Railspress.post_images_enabled?
        end

        def set_post
          @post = Railspress::Post.find(params[:post_id])
        end

        def set_gallery_image
          @gallery_image = @post.gallery_images.attachments.find(params[:id])
        end

        def gallery_image_source
          upload = params[:image] || params.dig(:gallery_image, :image)
          return { attachable: upload, content_type: upload.content_type } if upload.present?

          signed_blob_id = params[:signed_blob_id] || params.dig(:gallery_image, :signed_blob_id)
          return if signed_blob_id.blank?

          blob = ActiveStorage::Blob.find_signed(signed_blob_id)
          return { invalid: true } unless blob

          { attachable: blob, content_type: blob.content_type }
        end
      end
    end
  end
end
