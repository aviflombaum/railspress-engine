# frozen_string_literal: true

module Railspress
  module Admin
    class AgentBootstrapKeysController < BaseController
      DEFAULT_BOOTSTRAP_TTL = 1.hour

      before_action :ensure_api_enabled!
      before_action :require_api_actor!
      before_action :set_agent_bootstrap_key, only: [ :revoke ]

      def new
        @agent_bootstrap_key = AgentBootstrapKey.new(expires_at: default_bootstrap_expires_at)
      end

      def create
        @agent_bootstrap_key, @plain_bootstrap_token = AgentBootstrapKey.issue!(
          name: agent_bootstrap_key_params[:name],
          actor: current_api_actor,
          owner: current_api_actor,
          expires_at: parsed_expires_at || default_bootstrap_expires_at
        )
        set_bootstrap_instructions

        render :reveal, status: :created
      rescue ActiveRecord::RecordInvalid => e
        @agent_bootstrap_key = e.record
        render :new, status: :unprocessable_content
      end

      def revoke
        @agent_bootstrap_key.revoke!(
          actor: current_api_actor,
          reason: params[:reason].presence || "revoked"
        )

        redirect_to admin_api_keys_path, notice: "Agent bootstrap key revoked."
      end

      private

      def ensure_api_enabled!
        raise ActionController::RoutingError, "Not Found" unless Railspress.api_enabled?
      end

      def require_api_actor!
        return if current_api_actor.present?

        redirect_to admin_root_path, alert: "You must be signed in to manage API keys."
      end

      def set_agent_bootstrap_key
        @agent_bootstrap_key = AgentBootstrapKey.find(params[:id])
      end

      def agent_bootstrap_key_params
        params.require(:agent_bootstrap_key).permit(:name, :expires_at)
      end

      def parsed_expires_at
        value = agent_bootstrap_key_params[:expires_at]
        return nil if value.blank?

        Time.zone.parse(value)
      rescue ArgumentError
        nil
      end

      def default_bootstrap_expires_at
        DEFAULT_BOOTSTRAP_TTL.from_now
      end

      def set_bootstrap_instructions
        base_url = instruction_base_url

        @bootstrap_quick_start = <<~TEXT
          export RAILSPRESS_BOOTSTRAP_TOKEN="#{@plain_bootstrap_token}"
          export RAILSPRESS_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $RAILSPRESS_BOOTSTRAP_TOKEN" #{base_url}#{exchange_api_v1_agent_keys_path} | ruby -rjson -e 'print JSON.parse(STDIN.read).dig("data","api_key","token")')
          printf '%s\n' "$RAILSPRESS_TOKEN" > ~/.railspress_token
          chmod 600 ~/.railspress_token
          curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" #{base_url}#{api_v1_prime_path}
        TEXT

        @bootstrap_instructions = <<~TEXT
          I use Railspress for blog publishing. Here's the secure agent setup:

          Host: #{base_url}
          Bootstrap Token (one-time): #{@plain_bootstrap_token}
          Exchange Endpoint: #{base_url}#{exchange_api_v1_agent_keys_path}

          1) Exchange bootstrap for API token:
            export RAILSPRESS_BOOTSTRAP_TOKEN="#{@plain_bootstrap_token}"
            export RAILSPRESS_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $RAILSPRESS_BOOTSTRAP_TOKEN" #{base_url}#{exchange_api_v1_agent_keys_path} | ruby -rjson -e 'print JSON.parse(STDIN.read).dig("data","api_key","token")')

          2) Optional local token file:
            printf '%s\n' "$RAILSPRESS_TOKEN" > ~/.railspress_token
            chmod 600 ~/.railspress_token
            export RAILSPRESS_TOKEN="$(cat ~/.railspress_token)"

          3) Verify connectivity:
            curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" #{base_url}#{api_v1_prime_path}

          4) Create a draft post:
            curl -X POST -H "Authorization: Bearer $RAILSPRESS_TOKEN" -H "Content-Type: application/json" -d '{"post":{"title":"Agent draft","content":"<p>Hello</p>"}}' #{base_url}#{api_v1_posts_path}
        TEXT
      end
    end
  end
end
