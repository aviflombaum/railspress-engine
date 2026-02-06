# frozen_string_literal: true

module Railspress
  module SoftDeletable
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(deleted_at: nil) }
    end

    def deleted?
      deleted_at.present?
    end

    def soft_delete
      update(deleted_at: Time.current)
    end

    def restore
      update(deleted_at: nil)
    end
  end
end
