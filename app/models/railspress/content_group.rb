# frozen_string_literal: true

module Railspress
  class ContentGroup < ApplicationRecord
    include Railspress::SoftDeletable

    has_many :content_elements, dependent: :destroy

    validates :name, presence: true, uniqueness: true

    scope :ordered, -> { order(created_at: :desc) }
    scope :recent, -> { order(created_at: :desc) }

    def author
      return nil unless author_id.present? && Railspress.authors_enabled?
      Railspress.author_class.find_by(id: author_id)
    end

    def author=(user)
      self.author_id = user&.id
    end

    def element_count
      content_elements.active.count
    end

    def soft_delete
      if content_elements.active.where(required: true).exists?
        errors.add(:base, "Cannot delete group containing required content elements")
        false
      else
        transaction do
          content_elements.each(&:soft_delete)
          update!(deleted_at: Time.current)
        end
      end
    end
  end
end
