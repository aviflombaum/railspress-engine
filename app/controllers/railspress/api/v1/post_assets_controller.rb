# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostAssetsController < BaseController
        ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze

        def create
          source = asset_source
          return render_error("Invalid signed blob id.", status: :unprocessable_content) if source&.key?(:invalid)
          return render_error("Either image or signed_blob_id is required.", status: :unprocessable_content) unless source

          unless ALLOWED_CONTENT_TYPES.include?(source[:content_type])
            return render_error("Unsupported image type. Allowed: JPEG, PNG, GIF, WebP.", status: :unprocessable_content)
          end

          blob = source[:blob] || create_blob(source[:upload])
          attachment = ActionText::Attachment.from_attachable(blob)

          render json: {
            data: {
              blob_id: blob.id,
              signed_blob_id: blob.signed_id,
              attachable_sgid: blob.attachable_sgid,
              filename: blob.filename.to_s,
              byte_size: blob.byte_size,
              content_type: blob.content_type,
              attachment_html: attachment.to_html
            }
          }, status: :created
        end

        private

        def asset_source
          upload = params[:image] || params.dig(:asset, :image)
          return { upload: upload, content_type: upload.content_type } if upload.present?

          signed_blob_id = params[:signed_blob_id] || params.dig(:asset, :signed_blob_id)
          return if signed_blob_id.blank?

          blob = ActiveStorage::Blob.find_signed(signed_blob_id)
          return { invalid: true } unless blob

          { blob: blob, content_type: blob.content_type }
        end

        def create_blob(upload)
          ActiveStorage::Blob.create_and_upload!(
            io: upload,
            filename: upload.original_filename,
            content_type: upload.content_type
          )
        end
      end
    end
  end
end
