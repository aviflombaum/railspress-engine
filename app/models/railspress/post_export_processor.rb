require "zip"
require "fileutils"

module Railspress
  class PostExportProcessor
    attr_reader :export, :errors, :export_dir

    def initialize(export:)
      @export = export
      @errors = []
      @export_dir = nil
    end

    def process!
      export.mark_processing!

      setup_export_directory
      export_all_posts
      create_zip_file

      if export.error_count > 0 && export.success_count == 0
        export.mark_failed!
      else
        export.mark_completed!
      end
    ensure
      cleanup_export_directory
    end

    private

    def setup_export_directory
      @export_dir = Rails.root.join("tmp", "exports", "#{export.id}_#{Time.current.to_i}")
      FileUtils.mkdir_p(@export_dir)
      FileUtils.mkdir_p(File.join(@export_dir, "images"))
    end

    def cleanup_export_directory
      return unless @export_dir && Dir.exist?(@export_dir)
      FileUtils.rm_rf(@export_dir)
    rescue => e
      Rails.logger.warn "Failed to cleanup export tmp files: #{e.message}"
    end

    def export_all_posts
      Post.find_each do |post|
        export.increment_total!
        export_post(post)
      end
    end

    def export_post(post)
      filename = generate_filename(post)
      filepath = File.join(@export_dir, filename)

      frontmatter = build_frontmatter(post)
      content = extract_content(post)

      markdown = generate_markdown(frontmatter, content)
      File.write(filepath, markdown)

      export_header_image(post) if post.header_image.attached?

      export.increment_success!
    rescue => e
      export.add_error("#{post.title}: #{e.message}")
    end

    def generate_filename(post)
      slug = post.slug.presence || post.title.parameterize
      "#{slug}.md"
    end

    def build_frontmatter(post)
      fm = {
        "title" => post.title,
        "slug" => post.slug,
        "status" => post.status
      }

      fm["published_at"] = post.published_at.to_date.to_s if post.published_at.present?
      fm["category"] = post.category.name if post.category.present?
      fm["tags"] = post.tags.pluck(:name).join(", ") if post.tags.any?
      fm["meta_title"] = post.meta_title if post.meta_title.present?
      fm["meta_description"] = post.meta_description if post.meta_description.present?

      if Railspress.authors_enabled? && post.respond_to?(:author) && post.author.present?
        display_method = Railspress.author_display_method
        fm["author"] = post.author.public_send(display_method)
      end

      if post.header_image.attached?
        fm["header_image"] = "images/#{post.slug}.#{header_image_extension(post)}"
      end

      fm
    end

    def header_image_extension(post)
      post.header_image.filename.extension.downcase
    end

    def extract_content(post)
      return "" unless post.content.present?

      # ActionText stores HTML, we'll keep it as-is since redcarpet doesn't reverse
      # Most markdown parsers handle inline HTML fine
      post.content.body.to_html
    end

    def generate_markdown(frontmatter, content)
      yaml = frontmatter.to_yaml
      "#{yaml}---\n\n#{content}"
    end

    def export_header_image(post)
      return unless post.header_image.attached?

      extension = header_image_extension(post)
      image_filename = "#{post.slug}.#{extension}"
      image_path = File.join(@export_dir, "images", image_filename)

      File.open(image_path, "wb") do |file|
        file.write(post.header_image.download)
      end
    rescue => e
      Rails.logger.warn "Failed to export header image for #{post.slug}: #{e.message}"
    end

    def create_zip_file
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      zip_filename = "posts_export_#{timestamp}.zip"
      zip_path = Rails.root.join("tmp", zip_filename)

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        add_directory_to_zip(zipfile, @export_dir, "")
      end

      # Attach the zip to the export record
      export.file.attach(
        io: File.open(zip_path),
        filename: zip_filename,
        content_type: "application/zip"
      )

      export.update!(filename: zip_filename)

      # Clean up the temp zip file
      FileUtils.rm_f(zip_path)
    end

    def add_directory_to_zip(zipfile, dir, prefix)
      Dir.glob(File.join(dir, "**", "*")).each do |file|
        next if File.directory?(file)

        relative_path = file.sub("#{dir}/", "")
        entry_name = prefix.present? ? File.join(prefix, relative_path) : relative_path
        zipfile.add(entry_name, file)
      end
    end
  end
end
