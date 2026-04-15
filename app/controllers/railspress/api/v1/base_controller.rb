# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class BaseController < ActionController::API
        include ActionController::HttpAuthentication::Token::ControllerMethods

        before_action :ensure_api_enabled!
        before_action :authenticate_api_key!

        rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

        attr_reader :current_api_key

        private

        def ensure_api_enabled!
          render_error("API is not enabled.", status: :not_found) unless Railspress.api_enabled?
        end

        def authenticate_api_key!
          return if authenticate_with_http_token { |token, _opts| authenticate_with_token(token) }

          render_error("Unauthorized", status: :unauthorized)
        end

        def authenticate_with_token(token)
          @current_api_key = Railspress::ApiKey.authenticate(token, ip_address: request.remote_ip)
          @current_api_key.present?
        end

        def render_not_found
          render_error("Resource not found.", status: :not_found)
        end

        def render_validation_errors(record)
          render json: {
            error: {
              message: "Validation failed.",
              details: record.errors.full_messages
            }
          }, status: :unprocessable_content
        end

        def render_error(message, status:)
          render json: { error: { message: message } }, status: status
        end
      end
    end
  end
end
