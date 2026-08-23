# frozen_string_literal: true

module Railspress
  module Admin
    class AgentBootstrapKeysController < BaseController
      DEFAULT_BOOTSTRAP_TTL = 1.hour

      before_action :ensure_api_enabled!
      before_action :require_current_admin!
      before_action :set_agent_bootstrap_key, only: [ :revoke ]

      def new
        @agent_bootstrap_key = AgentBootstrapKey.new(expires_at: default_bootstrap_expires_at)
      end

      def create
        @agent_bootstrap_key, @plain_bootstrap_token = AgentBootstrapKey.issue!(
          name: agent_bootstrap_key_params[:name],
          actor: current_railspress_admin,
          owner: current_railspress_admin,
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
          actor: current_railspress_admin,
          reason: params[:reason].presence || "revoked"
        )

        redirect_to admin_api_keys_path, notice: "Agent bootstrap key revoked."
      end

      private

      def ensure_api_enabled!
        raise ActionController::RoutingError, "Not Found" unless Railspress.api_enabled?
      end

      def require_current_admin!
        return if current_railspress_admin.present?

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
          printf '%s\\n' "$RAILSPRESS_BOOTSTRAP_TOKEN" | #{railspress_agent_command} onboard --start /path/to/publishing-project --json
        TEXT

        @bootstrap_instructions = <<~TEXT
          I use Railspress for blog publishing. Here's the secure agent setup:

          Host: #{base_url}
          Bootstrap Token (one-time): #{@plain_bootstrap_token}
          API Base: #{instruction_api_base(base_url)}
          Token Path: #{instruction_token_file(base_url)}

          1) Save the token-free RAILSPRESS.md from Agents & API at the publishing project root.

          2) Review and explicitly trust its normalized values:
            #{railspress_agent_command} config check --start /path/to/publishing-project
            #{railspress_agent_command} config trust --start /path/to/publishing-project

          3) Exchange once, store the API key safely, and verify /prime:
            export RAILSPRESS_BOOTSTRAP_TOKEN="#{@plain_bootstrap_token}"
            printf '%s\\n' "$RAILSPRESS_BOOTSTRAP_TOKEN" | #{railspress_agent_command} onboard --start /path/to/publishing-project --json

          Never automatically retry an unknown exchange outcome. Inspect or revoke the
          server-side API key, then create a new bootstrap key.
        TEXT
      end
    end
  end
end
