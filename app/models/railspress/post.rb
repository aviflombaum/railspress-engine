module Railspress
  class Post < ApplicationRecord
    include Railspress::Entity
    include Railspress::Taggable

    # === Entity Field Declarations ===
    # These fields use the Entity system for type detection and config introspection.
    # Post is NOT registered as an entity (it keeps its dedicated controller/views).
    railspress_fields :title, :slug, :excerpt
    railspress_fields :meta_title, :meta_description
    railspress_fields :content                        # auto-detects :rich_text
    railspress_fields :header_image, as: :attachment
    railspress_fields :published_at, :reading_time

    # Fields NOT declared above (Entity doesn't support these types yet):
    # - category_id (belongs_to association)
    # - status (enum)
    # - author_id (configurable polymorphic)
    # - tags (has_many through)
    # See .ai/FUTURE_ENTITY.md for planned Entity enhancements

    railspress_label "Posts"

    # === Associations ===
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
    before_save :set_reading_time, if: -> { reading_time.blank? && content.present? }

    # Generic scopes (ordered, recent) and pagination (page) provided by Entity concern
    # Post-specific scopes below:
    scope :published, -> { where(status: :published).where.not(published_at: nil) }
    scope :drafts, -> { where(status: :draft) }
    scope :by_author, ->(author) { where(author_id: author.id) }
    scope :search, ->(query) { where("title ILIKE ?", "%#{query}%") if query.present? }
    scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
    scope :by_status, ->(status) { where(status: status) if status.present? }
    scope :sorted_by, ->(column, direction) {
      direction = direction.to_s.downcase == "desc" ? :desc : :asc
      case column.to_s
      when "title"
        order(title: direction)
      when "category"
        left_joins(:category).order(Arel.sql("railspress_categories.name #{direction == :desc ? 'DESC' : 'ASC'} NULLS LAST"))
      when "status"
        order(status: direction)
      when "reading_time"
        order(reading_time: direction)
      when "created_at"
        order(created_at: direction)
      else
        order(created_at: :desc)
      end
    }

    # Calculate reading time from content word count
    def calculate_reading_time
      return 1 unless content.present?

      words_per_minute = Railspress.words_per_minute
      word_count = content.to_plain_text.split(/\s+/).count
      minutes = (word_count.to_f / words_per_minute).ceil
      [ minutes, 1 ].max
    end

    # Display reading time with fallback to calculated value
    def reading_time_display
      reading_time.presence || calculate_reading_time
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

    def set_reading_time
      self.reading_time = calculate_reading_time
    end

    def purge_header_image
      header_image.purge_later
    end
  end
end
