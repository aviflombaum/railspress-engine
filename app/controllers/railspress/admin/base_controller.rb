module Railspress
  module Admin
    class BaseController < ActionController::Base
      layout "railspress/admin"

      # Authentication hook - to be configured later
      # before_action :authenticate_admin!

      private

      def set_flash(type, message)
        flash[type] = message
      end
    end
  end
end
