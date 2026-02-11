# frozen_string_literal: true

require "zip"
require "json"
require "fileutils"

module Railspress
  class ContentImportService
    Result = Struct.new(:created, :updated, :restored, :errors, keyword_init: true) do
      def total_processed
        created + updated + restored
      end

      def success?
        errors.empty?
      end
    end

    MAX_ZIP_SIZE = 50.megabytes
    MAX_ENTRIES = 500
    SUPPORTED_IMAGE_TYPES = %w[.jpg .jpeg .png .gif .webp].freeze

    def initialize(zip_file)
      @zip_file = zip_file
      @created = 0
      @updated = 0
      @restored = 0
      @errors = []
      @extract_dir = nil
    end

    def call
      validate_zip_size!
      extract_and_process
      Result.new(created: @created, updated: @updated, restored: @restored, errors: @errors)
    ensure
      cleanup_temp_dir
    end

    private

    def validate_zip_size!
      size = @zip_file.respond_to?(:size) ? @zip_file.size : File.size(@zip_file.path)
      if size > MAX_ZIP_SIZE
        raise ArgumentError, "ZIP file exceeds maximum size of #{MAX_ZIP_SIZE / 1.megabyte}MB"
      end
    end

    def extract_and_process
      @extract_dir = Rails.root.join("tmp", "cms_imports", "#{SecureRandom.hex(8)}")
      FileUtils.mkdir_p(@extract_dir)

      extract_zip!
      manifest = parse_manifest!

      manifest["groups"]&.each { |group_data| process_group(group_data) }

      CmsHelper.clear_cache if defined?(CmsHelper)
    end

    def extract_zip!
      zip_path = @zip_file.respond_to?(:path) ? @zip_file.path : @zip_file
      entry_count = 0

      Zip::File.open(zip_path) do |zip|
        zip.each do |entry|
          next if entry.name.start_with?("__MACOSX", ".")
          next unless safe_entry_name?(entry.name)

          entry_count += 1
          if entry_count > MAX_ENTRIES
            @errors << "ZIP contains more than #{MAX_ENTRIES} entries. Processing stopped."
            break
          end

          destination = File.join(@extract_dir, entry.name)
          FileUtils.mkdir_p(File.dirname(destination))
          entry.extract(destination) unless File.exist?(destination)
        end
      end
    rescue Zip::Error => e
      raise ArgumentError, "Invalid ZIP file: #{e.message}"
    end

    def parse_manifest!
      manifest_path = File.join(@extract_dir, "content.json")
      unless File.exist?(manifest_path)
        raise ArgumentError, "ZIP does not contain content.json"
      end

      manifest = JSON.parse(File.read(manifest_path))

      unless manifest.is_a?(Hash) && manifest["version"].present? && manifest["groups"].is_a?(Array)
        raise ArgumentError, "Invalid content.json schema: missing 'version' or 'groups'"
      end

      manifest
    rescue JSON::ParserError => e
      raise ArgumentError, "Invalid JSON in content.json: #{e.message}"
    end

    def process_group(group_data)
      name = group_data["name"]
      if name.blank?
        @errors << "Group missing name, skipped"
        return
      end

      # Unscoped find — includes soft-deleted
      group = ContentGroup.find_by(name: name)

      if group
        was_deleted = group.deleted?
        group.restore if was_deleted
        group.update!(description: group_data["description"])

        if was_deleted
          @restored += 1
        else
          @updated += 1
        end
      else
        group = ContentGroup.create!(name: name, description: group_data["description"])
        @created += 1
      end

      group_data["elements"]&.each { |el_data| process_element(group, el_data) }
    rescue => e
      @errors << "Group '#{group_data['name']}': #{e.message}"
    end

    def process_element(group, element_data)
      name = element_data["name"]
      if name.blank?
        @errors << "Element missing name in group '#{group.name}', skipped"
        return
      end

      # Unscoped find within group — includes soft-deleted
      element = ContentElement.unscoped
                              .where(content_group_id: group.id, name: name)
                              .first

      attrs = {
        content_type: element_data["content_type"],
        position: element_data["position"],
        text_content: element_data["text_content"],
        required: element_data.fetch("required", false),
        image_hint: element_data["image_hint"]
      }.compact

      if element
        was_deleted = element.deleted?
        element.restore if was_deleted
        element.update!(attrs)

        if was_deleted
          @restored += 1
        else
          @updated += 1
        end
      else
        element = group.content_elements.create!(attrs.merge(name: name))
        @created += 1
      end

      attach_image(element, element_data["image_path"], group) if element_data["image_path"].present?
      restore_focal_point(element, element_data["focal_point"]) if element_data["focal_point"].is_a?(Hash)
    rescue => e
      @errors << "Element '#{element_data['name']}' in '#{group.name}': #{e.message}"
    end

    def attach_image(element, image_path, group)
      unless safe_entry_name?(image_path)
        @errors << "Image file missing for '#{element.name}' in '#{group.name}': #{image_path}"
        return
      end

      full_path = File.join(@extract_dir, image_path)
      unless File.exist?(full_path)
        @errors << "Image file missing for '#{element.name}' in '#{group.name}': #{image_path}"
        return
      end

      ext = File.extname(full_path).downcase
      unless SUPPORTED_IMAGE_TYPES.include?(ext)
        @errors << "Unsupported image type '#{ext}' for '#{element.name}' in '#{group.name}'"
        return
      end

      content_type = case ext
                     when ".jpg", ".jpeg" then "image/jpeg"
                     when ".png" then "image/png"
                     when ".gif" then "image/gif"
                     when ".webp" then "image/webp"
                     end

      element.image.attach(
        io: File.open(full_path),
        filename: File.basename(full_path),
        content_type: content_type
      )
    end

    def restore_focal_point(element, focal_data)
      return unless element.respond_to?(:image_focal_point)

      fp = element.image_focal_point
      fp.update!(
        focal_x: focal_data["x"],
        focal_y: focal_data["y"]
      )
    rescue => e
      @errors << "Focal point for '#{element.name}': #{e.message}"
    end

    def safe_entry_name?(name)
      !name.include?("..") && !name.start_with?("/")
    end

    def cleanup_temp_dir
      return unless @extract_dir && Dir.exist?(@extract_dir.to_s)
      FileUtils.rm_rf(@extract_dir)
    rescue => e
      Rails.logger.warn "Failed to cleanup CMS import tmp files: #{e.message}"
    end
  end
end
