# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostHeaderImageContextsController < BaseController
        include Railspress::Api::V1::Concerns::PostSerialization

        rescue_from ActionController::BadRequest, with: :render_unprocessable_request

        before_action :ensure_post_images_enabled!
        before_action :ensure_focal_points_enabled!
        before_action :set_post
        before_action :ensure_header_image_attached!
        before_action :set_context, only: [ :show, :update, :destroy ]

        def index
          render json: {
            data: available_contexts.map do |context_name, context_config|
              serialize_header_image_context(@post, context_name, context_config: context_config)
            end
          }
        end

        def show
          render json: { data: serialize_header_image_context(@post, @context_name, context_config: @context_config) }
        end

        def update
          apply_context_override!
          return if performed?

          render json: {
            data: serialize_header_image_context(@post, @context_name, context_config: @context_config),
            post: serialize_post(@post.reload)
          }
        rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
          render_error("Invalid signed blob id.", status: :unprocessable_content)
        end

        def destroy
          @post.clear_image_override(@context_name, :header_image)
          @post.save!

          render json: {
            data: serialize_header_image_context(@post, @context_name, context_config: @context_config),
            post: serialize_post(@post.reload)
          }
        end

        private

        def ensure_post_images_enabled!
          render_error("Post images are not enabled.", status: :not_found) unless Railspress.post_images_enabled?
        end

        def ensure_focal_points_enabled!
          render_error("Focal points are not enabled.", status: :not_found) unless Railspress.focal_points_enabled?
        end

        def set_post
          @post = Railspress::Post.find(params[:post_id])
        end

        def ensure_header_image_attached!
          render_error("Header image is not attached.", status: :unprocessable_content) unless @post.header_image.attached?
        end

        def set_context
          @context_name = params[:context].to_s
          @context_config = available_contexts[@context_name.to_sym]
          return if @context_config.present?

          render_error("Image context not found.", status: :not_found)
        end

        def available_contexts
          @available_contexts ||= Railspress.image_contexts || {}
        end

        def apply_context_override!
          override = override_params

          case override[:type]
          when "focal"
            @post.clear_image_override(@context_name, :header_image)
          when "crop"
            @post.set_image_override(@context_name, {
              "type" => "crop",
              "region" => normalize_crop_region(override[:region])
            }, :header_image)
          when "upload"
            @post.set_image_override(@context_name, {
              "type" => "upload",
              "blob_signed_id" => signed_blob_id_for_upload(override)
            }, :header_image)
          else
            return render_error("Override type must be one of: focal, crop, upload.", status: :unprocessable_content)
          end

          return if @post.save

          render_validation_errors(@post.header_image_focal_point)
        end

        def override_params
          params.require(:override).permit(:type, :signed_blob_id, :blob_signed_id, region: [ :x, :y, :width, :height ])
        end

        def normalize_crop_region(raw_region)
          unless raw_region.present?
            raise ActionController::BadRequest, "Crop overrides require a region hash."
          end

          region = raw_region.to_h.transform_values { |value| Float(value) }
          validate_crop_region!(region)

          {
            "x" => region.fetch("x").to_f,
            "y" => region.fetch("y").to_f,
            "width" => region.fetch("width").to_f,
            "height" => region.fetch("height").to_f
          }
        rescue KeyError
          raise ActionController::BadRequest, "Crop region must include x, y, width, and height."
        rescue ArgumentError
          raise ActionController::BadRequest, "Crop region values must be numeric."
        end

        def validate_crop_region!(region)
          values = [ region.fetch("x"), region.fetch("y"), region.fetch("width"), region.fetch("height") ]
          if values.any? { |value| value.negative? || value > 1 }
            raise ActionController::BadRequest, "Crop region values must stay within 0..1."
          end

          if region.fetch("width").zero? || region.fetch("height").zero?
            raise ActionController::BadRequest, "Crop region width and height must be greater than 0."
          end

          if region.fetch("x") + region.fetch("width") > 1 || region.fetch("y") + region.fetch("height") > 1
            raise ActionController::BadRequest, "Crop region must fit within the source image bounds."
          end
        end

        def signed_blob_id_for_upload(override)
          signed_blob_id = override[:signed_blob_id].presence || override[:blob_signed_id].presence
          raise ActionController::BadRequest, "Upload overrides require signed_blob_id." if signed_blob_id.blank?

          ActiveStorage::Blob.find_signed!(signed_blob_id).signed_id
        end

        def render_unprocessable_request(error)
          render_error(error.message, status: :unprocessable_content)
        end
      end
    end
  end
end
