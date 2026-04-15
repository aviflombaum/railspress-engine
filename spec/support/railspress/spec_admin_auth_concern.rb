# frozen_string_literal: true

module Railspress
  module SpecAdminAuthConcern
    extend ActiveSupport::Concern

    included do
      helper_method :current_user
    end

    private

    def current_user
      actor_id = request.headers["X-Railspress-Actor-ID"]
      User.find_by(id: actor_id)
    end
  end
end
