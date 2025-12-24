module Railspress
  class Post < ApplicationRecord
    belongs_to :category, optional: true
    # Author association - only functional when Railspress.authors_enabled?
    # The author class is configured via Railspress.configure { |c| c.author_class_name = "User" }
    def author
      return nil unless author_id.present? && Railspress.authors_enabled?
      Railspress.author_class.find_by(id: author_id)
    end

    def author=(user)
      self.author_id = user&.id
    end
    has_many :post_tags, dependent: :destroy
    has_many :tags, through: :post_tags

    has_rich_text :content
    has_one_attached :header_image

    # Virtual attribute for removing header image via checkbox
    attr_accessor :remove_header_image
    before_save :purge_header_image, if: -> { remove_header_image == "1" }

    enum :status, { draft: 0, published: 1 }, default: :draft

    validates :title, presence: true
    validates :slug, presence: true, uniqueness: true

    before_validation :generate_slug, if: -> { slug.blank? && title.present? }
    before_save :set_published_at

    scope :ordered, -> { order(created_at: :desc) }
    scope :recent, -> { ordered.limit(10) }
    scope :published, -> { where(status: :published).where.not(published_at: nil) }
    scope :drafts, -> { where(status: :draft) }
    scope :by_author, ->(author) { where(author_id: author.id) }
    scope :search, ->(query) { where("title ILIKE ?", "%#{query}%") if query.present? }
    scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
    scope :by_status, ->(status) { where(status: status) if status.present? }

    PER_PAGE = 20

    def self.page(page_number)
      page_number = [page_number.to_i, 1].max
      offset((page_number - 1) * PER_PAGE).limit(PER_PAGE)
    end

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
      # Only auto-set if publishing and no date was manually provided
      if published? && published_at.nil?
        self.published_at = Time.current
      end
      # Note: We no longer clear published_at for drafts - allow scheduling
    end

    def purge_header_image
      header_image.purge_later
    end
  end
end
