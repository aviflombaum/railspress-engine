module Railspress
  module Admin
    class BaseController < ActionController::Base
      layout "railspress/admin"

      helper_method :current_author, :available_authors, :authors_enabled?, :header_images_enabled?

      # Authentication hook - to be configured later
      # before_action :authenticate_admin!

      private

      def set_flash(type, message)
        flash[type] = message
      end

      def authors_enabled?
        Railspress.authors_enabled?
      end

      def header_images_enabled?
        Railspress.header_images_enabled?
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
    end
  end
end
