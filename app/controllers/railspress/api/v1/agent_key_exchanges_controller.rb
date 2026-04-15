# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class AgentKeyExchangesController < BaseController
        include ActionController::HttpAuthentication::Token::ControllerMethods

        skip_before_action :authenticate_api_key!
        before_action :authenticate_bootstrap_key!

        def create
          api_key, plain_api_token = current_agent_bootstrap_key.exchange!(ip_address: request.remote_ip)

          render json: {
            data: {
              api_key: {
                id: api_key.id,
                name: api_key.name,
                token: plain_api_token,
                expires_at: api_key.expires_at
              },
              bootstrap: {
                id: current_agent_bootstrap_key.id,
                used_at: current_agent_bootstrap_key.used_at
              }
            }
          }, status: :created
        rescue Railspress::AgentBootstrapKey::ExchangeError
          render_error("Unauthorized", status: :unauthorized)
        rescue ActiveRecord::RecordInvalid => e
          render_validation_errors(e.record)
        end

        private

        attr_reader :current_agent_bootstrap_key

        def authenticate_bootstrap_key!
          authenticated = authenticate_with_http_token do |token, _opts|
            @current_agent_bootstrap_key = Railspress::AgentBootstrapKey.authenticate(token)
            @current_agent_bootstrap_key.present?
          end

          render_error("Unauthorized", status: :unauthorized) unless authenticated
        end
      end
    end
  end
end
