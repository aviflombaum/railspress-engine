# frozen_string_literal: true

module Railspress
  class ContentElement < ApplicationRecord
    include Railspress::SoftDeletable

    belongs_to :content_group
    has_many :content_element_versions, dependent: :destroy
    has_one_attached :image

    enum :content_type, { text: 0, image: 1 }

    validates :name, presence: true
    validates :content_type, presence: true
    validates :text_content, presence: true, if: :text?

    after_save :create_version, if: :should_create_version?

    scope :ordered, -> { order(position: :asc, created_at: :desc) }
    scope :recent, -> { order(updated_at: :desc) }
    scope :by_group, ->(content_group) { where(content_group: content_group) }
    scope :by_content_type, ->(type) { where(content_type: type) }

    def author
      return nil unless author_id.present? && Railspress.authors_enabled?
      Railspress.author_class.find_by(id: author_id)
    end

    def author=(user)
      self.author_id = user&.id
    end

    def value
      if text?
        text_content
      elsif image? && image.attached?
        Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
      end
    end

    def versions
      content_element_versions.ordered
    end

    def current_version
      content_element_versions.ordered.first
    end

    def previous_version
      content_element_versions.ordered.second
    end

    def version_count
      content_element_versions.count
    end

    def restore_to_version(version_number)
      version = content_element_versions.find_by(version_number: version_number)
      return false unless version

      update(text_content: version.text_content)
    end

    private

    def should_create_version?
      return false unless persisted?
      return false unless saved_changes.present?

      saved_change_to_text_content?
    end

    def create_version
      next_version_number = content_element_versions.maximum(:version_number).to_i + 1

      content_element_versions.create!(
        author_id: author_id,
        text_content: text_content_before_last_save || text_content,
        version_number: next_version_number
      )
    end
  end
end
