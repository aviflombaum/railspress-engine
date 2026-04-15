# frozen_string_literal: true

module Railspress
  module Admin
    class ApiKeysController < BaseController
      before_action :ensure_api_enabled!
      before_action :require_api_actor!
      before_action :set_api_key, only: [ :rotate, :revoke ]
      before_action :set_generic_agent_instructions, only: [ :index ]

      def index
        @api_keys = ApiKey.recent
        @agent_bootstrap_keys = AgentBootstrapKey.recent
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
        set_api_key_instructions

        render :reveal, status: :created
      rescue ActiveRecord::RecordInvalid => e
        @api_key = e.record
        render :new, status: :unprocessable_content
      end

      def rotate
        @api_key, @plain_token = @api_key.rotate!(
          actor: current_api_actor,
          expires_at: @api_key.expires_at
        )
        set_api_key_instructions
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

      def set_api_key_instructions
        base_url = instruction_base_url

        @api_key_quick_start = <<~TEXT
          export RAILSPRESS_TOKEN="#{@plain_token}"
          curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" #{base_url}#{api_v1_prime_path}
        TEXT

        @api_key_instructions = <<~TEXT
          I use Railspress for blog publishing. This is a direct API key.

          Host: #{base_url}
          API Key: #{@plain_token}
          API Base: #{base_url}#{api_v1_posts_path.delete_suffix("/posts")}

          Set environment variable:
            export RAILSPRESS_TOKEN="#{@plain_token}"

          Optional local token file:
            printf '%s\n' "#{@plain_token}" > ~/.railspress_token
            chmod 600 ~/.railspress_token
            export RAILSPRESS_TOKEN="$(cat ~/.railspress_token)"

          Quick start:
            #{api_key_quick_start_line}

          Create a draft post (default behavior):
            curl -X POST -H "Authorization: Bearer $RAILSPRESS_TOKEN" -H "Content-Type: application/json" -d '{"post":{"title":"Agent draft","content":"<p>Hello</p>"}}' #{base_url}#{api_v1_posts_path}

          Publish explicitly:
            set "post.status" to "published" (optionally also set "post.published_at")
        TEXT
      end

      def set_generic_agent_instructions
        bootstrap_token = latest_active_bootstrap_token || "<YOUR_BOOTSTRAP_TOKEN>"
        base_url = instruction_base_url

        @generic_agent_quick_start = <<~TEXT
          export RAILSPRESS_BOOTSTRAP_TOKEN="#{bootstrap_token}"
          export RAILSPRESS_TOKEN=$(curl -s -X POST -H "Authorization: Bearer ${RAILSPRESS_BOOTSTRAP_TOKEN}" #{base_url}#{exchange_api_v1_agent_keys_path} | ruby -rjson -e 'print JSON.parse(STDIN.read).dig("data","api_key","token")')
          curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" #{base_url}#{api_v1_prime_path}
        TEXT

        @generic_agent_instructions = <<~TEXT
          I use Railspress for blog publishing. Here's the secure agent flow:

          Host: #{base_url}
          Bootstrap Token: #{bootstrap_token}
          API Base: #{base_url}#{api_v1_posts_path.delete_suffix("/posts")}

          Exchange bootstrap token for a real API key (one-time bootstrap):
            export RAILSPRESS_BOOTSTRAP_TOKEN="#{bootstrap_token}"
            export RAILSPRESS_TOKEN=$(curl -s -X POST -H "Authorization: Bearer ${RAILSPRESS_BOOTSTRAP_TOKEN}" #{base_url}#{exchange_api_v1_agent_keys_path} | ruby -rjson -e 'print JSON.parse(STDIN.read).dig("data","api_key","token")')

          Optional local token file:
            printf '%s\n' "$RAILSPRESS_TOKEN" > ~/.railspress_token
            chmod 600 ~/.railspress_token
            export RAILSPRESS_TOKEN="$(cat ~/.railspress_token)"

          Quick start:
            curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" #{base_url}#{api_v1_prime_path}

          Create a draft post (default behavior):
            curl -X POST -H "Authorization: Bearer $RAILSPRESS_TOKEN" -H "Content-Type: application/json" -d '{"post":{"title":"Agent draft","content":"<p>Hello</p>"}}' #{base_url}#{api_v1_posts_path}

          Publish explicitly:
            set "post.status" to "published" (optionally also set "post.published_at")
        TEXT
      end

      def api_key_quick_start_line
        @api_key_quick_start.strip
      end

      def latest_active_bootstrap_token
        bootstrap_key = AgentBootstrapKey.active.recent.first
        return nil unless bootstrap_key

        AgentBootstrapKey.build_token(bootstrap_key.token_prefix, bootstrap_key.secret_ciphertext)
      end
    end
  end
end
