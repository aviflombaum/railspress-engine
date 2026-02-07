# frozen_string_literal: true

require "zip"
require "json"
require "fileutils"

module Railspress
  class ContentExportService
    Result = Struct.new(:zip_data, :filename, :group_count, :element_count, keyword_init: true)

    def call
      @group_count = 0
      @element_count = 0

      manifest = build_manifest
      zip_data = build_zip(manifest)
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")

      Result.new(
        zip_data: zip_data,
        filename: "cms_content_#{timestamp}.zip",
        group_count: @group_count,
        element_count: @element_count
      )
    end

    private

    def build_manifest
      groups = ContentGroup.active
                           .includes(content_elements: { image_attachment: :blob })
                           .order(:name)

      {
        "version" => 1,
        "exported_at" => Time.current.iso8601,
        "source" => "RailsPress CMS",
        "groups" => groups.map { |group| serialize_group(group) }
      }
    end

    def serialize_group(group)
      @group_count += 1
      elements = group.content_elements.active.ordered

      {
        "name" => group.name,
        "description" => group.description,
        "elements" => elements.map { |el| serialize_element(group, el) }
      }
    end

    def serialize_element(group, element)
      @element_count += 1

      data = {
        "name" => element.name,
        "content_type" => element.content_type,
        "position" => element.position,
        "text_content" => element.text_content
      }

      if element.image? && element.image.attached?
        data["image_path"] = image_path_for(group, element)
      end

      data
    end

    def build_zip(manifest)
      buffer = Zip::OutputStream.write_buffer do |zip|
        zip.put_next_entry("content.json")
        zip.write(JSON.pretty_generate(manifest))

        collect_images(manifest).each do |path, element_record|
          zip.put_next_entry(path)
          zip.write(element_record.image.download)
        end
      end

      buffer.string
    end

    def collect_images(manifest)
      images = {}

      manifest["groups"].each do |group_data|
        group = ContentGroup.find_by(name: group_data["name"])
        next unless group

        group_data["elements"].each do |el_data|
          next unless el_data["image_path"]

          element = group.content_elements.active.find_by(name: el_data["name"])
          next unless element&.image&.attached?

          images[el_data["image_path"]] = element
        end
      end

      images
    end

    def image_path_for(group, element)
      ext = element.image.filename.extension.downcase
      "images/#{sanitize_path(group.name)}/#{sanitize_path(element.name)}.#{ext}"
    end

    def sanitize_path(name)
      name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
    end
  end
end
