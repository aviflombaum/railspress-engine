# frozen_string_literal: true

module Railspress
  module Admin
    class ApiKeysController < BaseController
      before_action :ensure_api_enabled!
      before_action :require_api_actor!
      before_action :set_api_key, only: [ :rotate, :revoke ]

      def index
        @api_keys = ApiKey.recent
      end

      def new
        @api_key = ApiKey.new
      end

      def create
        @api_key, @plain_token = ApiKey.issue!(
          name: api_key_params[:name],
          actor: current_api_actor,
          owner: current_api_actor,
          expires_at: parsed_expires_at
        )

        render :reveal, status: :created
      rescue ActiveRecord::RecordInvalid => e
        @api_key = e.record
        render :new, status: :unprocessable_content
      end

      def rotate
        @api_key, @plain_token = @api_key.rotate!(actor: current_api_actor)
        render :reveal, status: :created
      end

      def revoke
        @api_key.revoke!(
          actor: current_api_actor,
          reason: params[:reason].presence || "revoked"
        )

        redirect_to admin_api_keys_path, notice: "API key revoked."
      end

      private

      def ensure_api_enabled!
        raise ActionController::RoutingError, "Not Found" unless Railspress.api_enabled?
      end

      def require_api_actor!
        return if current_api_actor.present?

        redirect_to admin_root_path, alert: "You must be signed in to manage API keys."
      end

      def set_api_key
        @api_key = ApiKey.find(params[:id])
      end

      def api_key_params
        params.require(:api_key).permit(:name, :expires_at)
      end

      def parsed_expires_at
        value = api_key_params[:expires_at]
        return nil if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end
    end
  end
end
