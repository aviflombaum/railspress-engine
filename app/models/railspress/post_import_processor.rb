require "yaml"
require "zip"
require "open-uri"
require "fileutils"

module Railspress
  class PostImportProcessor
    MARKDOWN_EXTENSIONS = %w[.md .markdown].freeze
    TEXT_EXTENSIONS = %w[.txt].freeze
    ZIP_EXTENSIONS = %w[.zip].freeze
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp].freeze
    FRONTMATTER_REGEX = /\A---\s*\n(.*?\n?)^---\s*\n/m

    attr_reader :import, :file_path, :errors, :extract_dir

    def initialize(import:, file_path:)
      @import = import
      @file_path = file_path
      @errors = []
      @extract_dir = nil
    end

    def process!
      import.mark_processing!

      process_file(file_path)

      if import.error_count > 0
        import.mark_failed! if import.success_count == 0
        import.mark_completed! if import.success_count > 0
      else
        import.mark_completed!
      end
    end

    def process_file(path, base_dir: nil)
      extension = File.extname(path).downcase

      if MARKDOWN_EXTENSIONS.include?(extension)
        process_markdown(path, base_dir: base_dir)
      elsif TEXT_EXTENSIONS.include?(extension)
        process_text(path, base_dir: base_dir)
      elsif ZIP_EXTENSIONS.include?(extension)
        process_zip(path)
      else
        import.add_error("Unsupported file type: #{File.basename(path)}")
      end
    end

    private

    def process_zip(path)
      @extract_dir = Rails.root.join("tmp", "imports", "#{import.id}_#{Time.current.to_i}")
      FileUtils.mkdir_p(@extract_dir)

      begin
        # Extract all files from zip
        Zip::File.open(path) do |zip_file|
          zip_file.each do |entry|
            next if entry.name.start_with?("__MACOSX", ".")

            destination = File.join(@extract_dir, entry.name)
            FileUtils.mkdir_p(File.dirname(destination))
            entry.extract(destination) unless File.exist?(destination)
          end
        end

        # Find and process all markdown/text files
        discover_files(@extract_dir).each do |file_path|
          process_file(file_path, base_dir: @extract_dir)
        end
      rescue Zip::Error => e
        import.add_error("#{File.basename(path)}: Invalid zip file - #{e.message}")
      rescue => e
        import.add_error("#{File.basename(path)}: #{e.message}")
      ensure
        cleanup_tmp_files
      end
    end

    def discover_files(directory)
      files = []
      Dir.glob(File.join(directory, "**", "*")).each do |path|
        next unless File.file?(path)
        ext = File.extname(path).downcase
        files << path if MARKDOWN_EXTENSIONS.include?(ext) || TEXT_EXTENSIONS.include?(ext)
      end
      files.sort
    end

    def cleanup_tmp_files
      return unless @extract_dir && Dir.exist?(@extract_dir)
      FileUtils.rm_rf(@extract_dir)
    rescue => e
      Rails.logger.warn "Failed to cleanup import tmp files: #{e.message}"
    end

    def process_markdown(path, base_dir: nil)
      import.increment_total!
      content = File.read(path, encoding: "UTF-8")

      frontmatter, body = extract_frontmatter(content)

      if body.blank? && frontmatter[:title].blank?
        import.add_error("#{File.basename(path)}: No content or title found")
        return
      end

      create_post(frontmatter, body, path, base_dir: base_dir)
    rescue => e
      import.add_error("#{File.basename(path)}: #{e.message}")
    end

    def process_text(path, base_dir: nil)
      import.increment_total!
      content = File.read(path, encoding: "UTF-8")

      if content.blank?
        import.add_error("#{File.basename(path)}: File is empty")
        return
      end

      # Title from filename: "my-blog-post.txt" -> "My Blog Post"
      title = File.basename(path, ".*").tr("-_", " ").titleize
      frontmatter = { title: title }

      create_post(frontmatter, content, path, base_dir: base_dir)
    rescue => e
      import.add_error("#{File.basename(path)}: #{e.message}")
    end

    def extract_frontmatter(content)
      if content.match?(FRONTMATTER_REGEX)
        match = content.match(FRONTMATTER_REGEX)
        yaml_content = match[1]
        body = content.sub(FRONTMATTER_REGEX, "").strip

        begin
          parsed = YAML.safe_load(yaml_content, permitted_classes: [Date, Time, DateTime], symbolize_names: true) || {}
          [parsed, body]
        rescue Psych::SyntaxError => e
          raise "Invalid YAML frontmatter: #{e.message}"
        end
      else
        # No frontmatter, treat entire content as body
        [{}, content.strip]
      end
    end

    def create_post(frontmatter, body, source_path, base_dir: nil)
      title = frontmatter[:title]

      if title.blank?
        # Try to get title from first heading or filename
        title = extract_title_from_body(body) || File.basename(source_path, ".*").tr("-_", " ").titleize
      end

      if title.blank?
        import.add_error("#{File.basename(source_path)}: No title found")
        return
      end

      post = Post.new(
        title: title,
        slug: frontmatter[:slug].presence,
        status: parse_status(frontmatter[:status]),
        published_at: parse_date(frontmatter[:published_at]),
        meta_title: frontmatter[:meta_title].presence,
        meta_description: frontmatter[:meta_description].presence
      )

      # Set rich text content
      post.content = body if body.present?

      # Handle associations
      assign_author(post, frontmatter[:author])
      assign_category(post, frontmatter[:category])
      assign_tags(post, frontmatter[:tags])

      if post.save
        # Attach header image after save (needs post.id for ActiveStorage)
        attach_header_image(post, frontmatter[:header_image], source_path, base_dir)
        import.increment_success!
      else
        import.add_error("#{File.basename(source_path)}: #{post.errors.full_messages.join(', ')}")
      end

      post
    end

    def attach_header_image(post, header_image_value, source_path, base_dir)
      return unless header_image_value.present?
      return unless Railspress.header_images_enabled?

      if url?(header_image_value)
        attach_image_from_url(post, header_image_value)
      elsif base_dir
        attach_image_from_zip(post, header_image_value, source_path, base_dir)
      end
    rescue => e
      Rails.logger.warn "Failed to attach header image for post #{post.id}: #{e.message}"
    end

    def url?(value)
      value.to_s.match?(/\Ahttps?:\/\//i)
    end

    def attach_image_from_url(post, url)
      uri = URI.parse(url)
      filename = File.basename(uri.path)
      filename = "header_image#{File.extname(uri.path)}" if filename.blank?

      downloaded = URI.open(url)
      post.header_image.attach(
        io: downloaded,
        filename: filename,
        content_type: downloaded.content_type
      )
    rescue OpenURI::HTTPError, URI::InvalidURIError => e
      Rails.logger.warn "Failed to download header image from #{url}: #{e.message}"
    end

    def attach_image_from_zip(post, relative_path, source_path, base_dir)
      # Resolve relative path from the markdown file's directory or from base_dir
      source_dir = File.dirname(source_path)

      # Try relative to the markdown file first
      image_path = File.expand_path(relative_path, source_dir)

      # If not found, try relative to base_dir
      unless File.exist?(image_path)
        image_path = File.expand_path(relative_path, base_dir)
      end

      return unless File.exist?(image_path)

      ext = File.extname(image_path).downcase
      return unless IMAGE_EXTENSIONS.include?(ext)

      content_type = case ext
                     when ".jpg", ".jpeg" then "image/jpeg"
                     when ".png" then "image/png"
                     when ".gif" then "image/gif"
                     when ".webp" then "image/webp"
                     else "application/octet-stream"
                     end

      post.header_image.attach(
        io: File.open(image_path),
        filename: File.basename(image_path),
        content_type: content_type
      )
    end

    def extract_title_from_body(body)
      # Look for first H1: # Title
      if match = body.match(/^#\s+(.+)$/)
        match[1].strip
      end
    end

    def parse_status(status)
      return :draft if status.blank?

      status_str = status.to_s.downcase
      Post.statuses.key?(status_str) ? status_str.to_sym : :draft
    end

    def parse_date(date)
      return Date.current if date.blank?

      case date
      when Date, Time, DateTime
        date.to_date
      when String
        Date.parse(date)
      else
        Date.current
      end
    rescue ArgumentError
      Date.current
    end

    def assign_author(post, author_value)
      return unless author_value.present?
      return unless Railspress.authors_enabled?

      author_class = Railspress.author_class
      display_method = Railspress.author_display_method

      # Build a case-insensitive query using the display method
      # e.g., if display_method is :name, we search by name
      begin
        author = author_class.where(
          "LOWER(#{display_method}) = ?",
          author_value.to_s.downcase
        ).first

        post.author_id = author.id if author
      rescue ActiveRecord::StatementInvalid
        # Column doesn't exist or other DB error - skip author assignment
        nil
      end
    end

    def assign_category(post, category_value)
      return unless category_value.present?

      category = Category.where("LOWER(name) = ?", category_value.to_s.downcase).first
      post.category = category if category
    end

    def assign_tags(post, tags_value)
      return unless tags_value.present?

      # Tags can be string (csv) or array
      csv = tags_value.is_a?(Array) ? tags_value.join(", ") : tags_value.to_s
      post.tag_list = csv
    end
  end
end
