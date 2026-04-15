# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PostHeaderImageFocalPointsController < BaseController
        include Railspress::Api::V1::Concerns::PostSerialization

        before_action :ensure_post_images_enabled!
        before_action :ensure_focal_points_enabled!
        before_action :set_post
        before_action :ensure_header_image_attached!

        def show
          render json: { data: serialize_focal_point(current_focal_point) }
        end

        def update
          focal_point = current_focal_point

          if focal_point.update(focal_point_params)
            render json: {
              data: serialize_focal_point(focal_point),
              post: serialize_post(@post.reload)
            }
          else
            render_validation_errors(focal_point)
          end
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

        def current_focal_point
          focal_point = @post.header_image_focal_point
          focal_point.save! if focal_point.new_record?
          focal_point
        end

        def focal_point_params
          permitted = params.require(:focal_point).permit(:focal_x, :focal_y, overrides: {})
          permitted[:overrides] = normalize_overrides(permitted[:overrides])
          permitted
        end

        def normalize_overrides(overrides)
          return {} if overrides.blank?
          return overrides.to_unsafe_h if overrides.is_a?(ActionController::Parameters)
          return overrides if overrides.is_a?(Hash)
          return JSON.parse(overrides) if overrides.is_a?(String)

          {}
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
