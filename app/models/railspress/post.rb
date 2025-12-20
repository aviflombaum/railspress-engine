module Railspress
  class Post < ApplicationRecord
    belongs_to :category, optional: true
    has_many :post_tags, dependent: :destroy
    has_many :tags, through: :post_tags

    has_rich_text :content

    enum :status, { draft: 0, published: 1 }, default: :draft

    validates :title, presence: true
    validates :slug, presence: true, uniqueness: true

    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
    before_save :set_published_at

    scope :ordered, -> { order(created_at: :desc) }
    scope :recent, -> { ordered.limit(10) }
    scope :published, -> { where(status: :published).where.not(published_at: nil) }
    scope :drafts, -> { where(status: :draft) }

    # Accepts CSV string and syncs tags
    def tag_list=(csv_string)
      self.tags = Tag.from_csv(csv_string)
    end

    def tag_list
      tags.pluck(:name).join(", ")
    end

    private

    def generate_slug
      base_slug = title.parameterize
      slug_candidate = base_slug
      counter = 1

      while self.class.where(slug: slug_candidate).where.not(id: id).exists?
        slug_candidate = "#{base_slug}-#{counter}"
        counter += 1
      end

      self.slug = slug_candidate
    end

    def set_published_at
      if published? && published_at.nil?
        self.published_at = Time.current
      elsif draft?
        self.published_at = nil
      end
    end
  end
end
