# frozen_string_literal: true

module Railspress
  module Admin
    class ContentElementVersionsController < BaseController
      def show
        @version = ContentElementVersion.find(params[:id])
        @content_element = @version.content_element
      end
    end
  end
end
