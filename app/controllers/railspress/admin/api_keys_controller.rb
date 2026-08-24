# frozen_string_literal: true

module Railspress
  module Admin
    class ApiKeysController < BaseController
      before_action :ensure_api_enabled!
      before_action :require_current_admin!
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
          actor: current_railspress_admin,
          owner: current_railspress_admin,
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
          actor: current_railspress_admin,
          expires_at: @api_key.expires_at
        )
        set_api_key_instructions
        render :reveal, status: :created
      end

      def revoke
        @api_key.revoke!(
          actor: current_railspress_admin,
          reason: params[:reason].presence || "revoked"
        )

        redirect_to admin_api_keys_path, notice: "API key revoked."
      end

      private

      def ensure_api_enabled!
        raise ActionController::RoutingError, "Not Found" unless Railspress.api_enabled?
      end

      def require_current_admin!
        return if current_railspress_admin.present?

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
        token_file = instruction_token_file(base_url)

        @api_key_quick_start = <<~TEXT
          export RAILSPRESS_TOKEN="#{@plain_token}"
          export RAILSPRESS_TOKEN_FILE="#{token_file}"
          printf '%s\\n' "$RAILSPRESS_TOKEN" | #{railspress_agent_command} token store "$RAILSPRESS_TOKEN_FILE"
          #{railspress_agent_command} prime --start /path/to/publishing-project --json
        TEXT

        @api_key_instructions = <<~TEXT
          I use Railspress for blog publishing. This is a direct API key.

          Host: #{base_url}
          API Key: #{@plain_token}
          API Base: #{instruction_api_base(base_url)}

          Save the token-free project manifest shown on Agents & API as RAILSPRESS.md,
          then review and approve its trust binding:
            #{railspress_agent_command} config check --start /path/to/publishing-project
            #{railspress_agent_command} config trust --start /path/to/publishing-project

          Store this one-time-visible API key through RailsPress Agent:
            export RAILSPRESS_TOKEN="#{@plain_token}"
            export RAILSPRESS_TOKEN_FILE="#{token_file}"
            printf '%s\\n' "$RAILSPRESS_TOKEN" | #{railspress_agent_command} token store "$RAILSPRESS_TOKEN_FILE"

          Verify connectivity and capabilities:
            #{railspress_agent_command} prime --start /path/to/publishing-project --json

          Manual content API example (the CLI currently owns setup and prime):
            export RAILSPRESS_TOKEN="$(cat "$RAILSPRESS_TOKEN_FILE")"
            curl -X POST -H "Authorization: Bearer $RAILSPRESS_TOKEN" -H "Content-Type: application/json" -d '{"post":{"title":"Agent draft","content":"<p>Hello</p>"}}' #{base_url}#{api_v1_posts_path}

          Publish explicitly:
            set "post.status" to "published" (optionally also set "post.published_at")
        TEXT
      end

      def set_generic_agent_instructions
        bootstrap_token = "<YOUR_BOOTSTRAP_TOKEN>"
        base_url = instruction_base_url
        @railspress_manifest = instruction_manifest(base_url)
        @railspress_agent_install = <<~TEXT
          curl -fsSL https://agent.railspress.org/install.sh | sh
        TEXT

        @manual_agent_instructions = <<~TEXT
          Manual RailsPress agent protocol (use only when RailsPress Agent cannot be installed):

          Host: #{base_url}
          API Base: #{instruction_api_base(base_url)}
          Bootstrap Exchange: #{base_url}#{exchange_api_v1_agent_keys_path}
          Agent Setup Key: #{bootstrap_token} (obtain it from its one-time reveal page)
          API Token Path: #{instruction_token_file(base_url)}

          1) Save the token-free RAILSPRESS.md shown on this page in the publishing project root.

          2) Validate and show the host, API base, and token path. Obtain explicit approval before sending credentials.

          3) Send the rpb_ setup key exactly once to the exchange endpoint as Bearer authentication. Do not follow redirects or retry an unknown outcome. Require 201 JSON and store only data.api_key.token outside the repository with owner-only permissions.

          4) Before every write, call API Base + /prime with the stored rp_ API key. Require compatible JSON and use its capabilities and endpoint paths.

          5) Create drafts by default. Publish or delete only when explicitly requested.

          If exchange may have succeeded but the response or storage outcome is unknown, do not exchange again. Ask an administrator to inspect and revoke any minted API key before issuing another Agent Setup Key.
        TEXT
      end
    end
  end
end
