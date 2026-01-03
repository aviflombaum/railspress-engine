module Railspress
  class Tag < ApplicationRecord
    has_many :taggings, dependent: :destroy

    # Explicit reverse associations for each taggable type
    has_many :posts,
             through: :taggings,
             source: :taggable,
             source_type: "Railspress::Post"

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :slug, presence: true, uniqueness: true

    before_validation :normalize_name
    before_validation :generate_slug, if: -> { slug.blank? && name.present? }

    scope :ordered, -> { order(:name) }

    # Find or create tags from CSV string
    def self.from_csv(csv_string)
      return [] if csv_string.blank?

      tag_names = csv_string.split(",").map { |t| t.strip.downcase }.reject(&:blank?).uniq
      tag_names.map { |name| find_or_create_by(name: name) }
    end

    private

    def normalize_name
      self.name = name.strip.downcase if name.present?
    end

    def generate_slug
      self.slug = name.parameterize
    end
  end
end
