# frozen_string_literal: true

module Railspress
  class ContentElementVersion < ApplicationRecord
    belongs_to :content_element
    has_one_attached :image_version

    validates :content_element, presence: true
    validates :version_number, presence: true, uniqueness: { scope: :content_element_id }

    scope :ordered, -> { order(version_number: :desc) }
    scope :recent, -> { order(created_at: :desc) }

    def author
      return nil unless author_id.present? && Railspress.authors_enabled?
      Railspress.author_class.find_by(id: author_id)
    end

    def changes_from_previous
      previous = content_element.content_element_versions
                                .where("version_number < ?", version_number)
                                .order(version_number: :desc)
                                .first

      return {} unless previous

      changes = {}
      changes[:text_content] = [previous.text_content, text_content] if text_content != previous.text_content
      changes.compact
    end
  end
end
