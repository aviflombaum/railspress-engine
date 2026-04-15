# frozen_string_literal: true

module Railspress
  module Api
    module V1
      class PrimeController < BaseController
        def show
          render json: {
            data: {
              service: "Railspress API",
              version: "v1",
              authentication: {
                type: "bearer",
                token_types: [ "api_key", "agent_bootstrap_key" ],
                agent_bootstrap_exchange_endpoint: exchange_api_v1_agent_keys_path
              },
              defaults: {
                post_status: "draft",
                publish_with_explicit_status: true
              },
              capabilities: capabilities,
              endpoints: endpoints,
              key: {
                id: current_api_key.id,
                name: current_api_key.name,
                status: current_api_key.status,
                expires_at: current_api_key.expires_at,
                last_used_at: current_api_key.last_used_at
              },
              server_time: Time.current
            }
          }
        end

        private

        def capabilities
          {
            posts: {
              list: true,
              read: true,
              create: true,
              update: true,
              delete: true,
              rich_text_html: true,
              default_status: "draft",
              publish_supported: true
            },
            post_imports: {
              create: true,
              read: true,
              formats: %w[md markdown txt zip]
            },
            post_media: {
              header_image: Railspress.post_images_enabled?,
              focal_points: Railspress.post_images_enabled? && Railspress.focal_points_enabled?,
              context_overrides: Railspress.post_images_enabled? && Railspress.focal_points_enabled?
            },
            taxonomies: {
              categories: true,
              tags: true
            }
          }
        end

        def endpoints
          {
            prime: api_v1_prime_path,
            posts: api_v1_posts_path,
            post_imports: api_v1_post_imports_path,
            categories: api_v1_categories_path,
            tags: api_v1_tags_path
          }
        end
      end
    end
  end
end
