# frozen_string_literal: true

module Railspress
  module Api
    module V1
      module Concerns
        module PostSerialization
          private

          def serialize_post(post)
            {
              id: post.id,
              title: post.title,
              slug: post.slug,
              status: post.status,
              published_at: post.published_at,
              reading_time: post.reading_time_display,
              meta_title: post.meta_title,
              meta_description: post.meta_description,
              category_id: post.category_id,
              author_id: post.author_id,
              author_display: serialize_author_display(post),
              tag_list: post.tag_list,
              content: post.content&.to_s,
              header_image: serialize_header_image(post),
              header_image_focal_point: serialize_header_image_focal_point(post),
              created_at: post.created_at,
              updated_at: post.updated_at
            }
          end

          def serialize_header_image(post)
            return nil unless Railspress.post_images_enabled?
            return { attached: false } unless post.header_image.attached?

            blob = post.header_image.blob

            {
              attached: true,
              blob_id: blob.id,
              signed_blob_id: blob.signed_id,
              filename: blob.filename.to_s,
              byte_size: blob.byte_size,
              content_type: blob.content_type
            }
          end

          def serialize_focal_point(focal_point)
            {
              id: focal_point.id,
              attachment_name: focal_point.attachment_name,
              focal_x: focal_point.focal_x.to_f,
              focal_y: focal_point.focal_y.to_f,
              overrides: focal_point.overrides || {}
            }
          end

          def serialize_header_image_focal_point(post)
            return nil unless Railspress.post_images_enabled? && Railspress.focal_points_enabled?
            return nil unless post.header_image.attached?

            focal_point = post.header_image_focal_point
            focal_point.save! if focal_point.new_record?
            serialize_focal_point(focal_point)
          end

          def serialize_header_image_context(post, context_name, context_config: nil)
            context_name = context_name.to_s
            context_config ||= Railspress.image_contexts[context_name.to_sym]
            override = post.image_override(context_name, :header_image)

            {
              name: context_name,
              label: context_config&.dig(:label) || context_name.humanize,
              aspect: context_config&.dig(:aspect),
              sizes: context_config&.dig(:sizes) || [],
              has_override: post.has_image_override?(context_name, :header_image),
              override: serialize_context_override(override),
              image_css: post.image_css_for(context_name, :header_image),
              image: serialize_context_image(post, context_name, override)
            }
          end

          def serialize_author_display(post)
            return nil unless Railspress.authors_enabled?
            return nil unless post.author.present?

            configured_method = Railspress.author_display_method
            if configured_method.present? && post.author.respond_to?(configured_method)
              configured_value = post.author.public_send(configured_method)
              return configured_value if configured_value.present?
            end

            fallback_method = [ :name, :full_name, :display_name, :email, :email_address ]
              .find { |method| post.author.respond_to?(method) && post.author.public_send(method).present? }

            fallback_method ? post.author.public_send(fallback_method) : "Author ##{post.author.id || "unknown"}"
          end

          def serialize_context_override(override)
            return { type: "focal" } if override.blank?

            override.to_h.deep_stringify_keys
          end

          def serialize_context_image(post, context_name, override)
            image = post.image_for(context_name, :header_image)
            blob = if image.is_a?(ActiveStorage::Blob)
              image
            elsif image.respond_to?(:blob)
              image.blob
            end
            return nil unless blob.present?

            override_type = override&.dig(:type) || override&.dig("type")

            {
              source: override_type == "upload" ? "upload_override" : "header_image",
              blob_id: blob.id,
              signed_blob_id: blob.signed_id,
              filename: blob.filename.to_s,
              byte_size: blob.byte_size,
              content_type: blob.content_type
            }
          end
        end
      end
    end
  end
end
