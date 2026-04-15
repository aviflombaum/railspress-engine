require "uri"

module Railspress
  module Admin
    class BaseController < ActionController::Base
      protect_from_forgery with: :exception

      layout "railspress/admin"
      helper Railspress::AdminHelper

      helper_method :current_author, :available_authors, :authors_enabled?, :post_images_enabled?, :current_api_actor

      # Authentication hook - to be configured later
      # before_action :authenticate_admin!

      private

      def set_flash(type, message)
        flash[type] = message
      end

      def authors_enabled?
        Railspress.authors_enabled?
      end

      def post_images_enabled?
        Railspress.post_images_enabled?
      end

      def current_author
        return nil unless authors_enabled?

        # Use proc if configured (most flexible)
        if Railspress.current_author_proc
          instance_exec(&Railspress.current_author_proc)
        # Otherwise try to call the configured method on self
        elsif respond_to?(Railspress.current_author_method, true)
          send(Railspress.current_author_method)
        end
      end

      def available_authors
        return [] unless authors_enabled?
        Railspress.available_authors
      end

      def current_api_actor
        if Railspress.current_api_actor_proc
          instance_exec(&Railspress.current_api_actor_proc)
        elsif respond_to?(Railspress.current_api_actor_method, true)
          send(Railspress.current_api_actor_method)
        end
      end

      def instruction_base_url
        configured = Railspress.public_base_url.to_s.strip
        return configured.delete_suffix("/") if configured.present?

        route_default_base_url || request.base_url
      end

      def route_default_base_url
        options = Rails.application.routes.default_url_options.to_h.symbolize_keys
        host_value = options[:host].presence
        return nil if host_value.blank?

        fallback_protocol = request.protocol.delete_suffix("://")
        parsed_uri = parse_host_uri(host_value, fallback_protocol)
        return nil if parsed_uri.nil? || parsed_uri.host.blank?

        protocol = options[:protocol].presence&.to_s&.delete_suffix("://") || parsed_uri.scheme || fallback_protocol
        port = options.key?(:port) ? options[:port] : parsed_uri.port
        script_name = options[:script_name].presence || parsed_uri.path.presence

        base = +"#{protocol}://#{parsed_uri.host}"
        base << ":#{port}" if non_default_port?(protocol, port)
        base << normalize_script_name(script_name) if script_name.present?
        base.delete_suffix("/")
      end

      def parse_host_uri(host_value, protocol)
        host_string = host_value.to_s
        host_string = "#{protocol}://#{host_string}" unless host_string.match?(/\Ahttps?:\/\//i)
        URI.parse(host_string)
      rescue URI::InvalidURIError
        nil
      end

      def non_default_port?(protocol, port)
        return false if port.blank?

        port_int = port.to_i
        return false if port_int.zero?

        !((protocol == "http" && port_int == 80) || (protocol == "https" && port_int == 443))
      end

      def normalize_script_name(script_name)
        value = script_name.to_s
        return "" if value.blank? || value == "/"

        value.start_with?("/") ? value : "/#{value}"
      end
    end
  end
end
