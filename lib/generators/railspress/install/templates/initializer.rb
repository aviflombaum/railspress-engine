# frozen_string_literal: true

# RailsPress configuration
#
# Full reference: docs/CONFIGURING.md in the railspress-engine gem
# Verify changes with: bin/rails railspress:doctor

Railspress.configure do |config|
  # === Admin Authentication ===

  # RailsPress admin controllers inherit your host ApplicationController.
  # Set the host method that protects /railspress/admin. Leave this unset only
  # when an inherited callback already protects the RailsPress admin.
  # Default: nil
  # config.admin_authentication_method = :require_admin!
  # Devise example: config.admin_authentication_method = :authenticate_user!

  # Method that returns the signed-in administrator for audited actions.
  # Default: :current_user
  # config.current_admin_method = :current_user

  # Proc alternative for Current/session-based identity. When set, this takes
  # precedence over current_admin_method. Default: nil
  # config.current_admin_proc = -> { Current.user }

  # Optional host concern to include in Railspress::Admin::BaseController.
  # Most applications do not need this. Default: nil
  # config.admin_auth_concern = "RailspressAdminAuth"

  # === Posts ===

  # Header and gallery images for posts. Enabled for new installations.
  config.enable_post_images

  # Post-image crop focus and context overrides. Requires post images and is
  # enabled for new installations.
  config.enable_focal_points

  # Named Active Storage variants available through
  # post.header_image.variant(:hero). RailsPress adds format: :webp.
  # Variants require ruby-vips or mini_magick. Default: {}
  # config.post_image_variants = {
  #   hero: { resize_to_fill: [1920, 1080] },
  #   card: { resize_to_fill: [800, 600] },
  #   thumb: { resize_to_fill: [400, 400] }
  # }

  # Public path used by the admin's "View post" links. This is separate from
  # the RailsPress engine mount path. Default: "/blog"
  # config.blog_path = "/posts"

  # Reading speed used for estimated reading time. Default: 200
  # config.words_per_minute = 250

  # === Authors (opt-in) ===

  # Connect posts and CMS records to a host-app author model.
  # config.enable_authors

  # Host author model. Default: "User"
  # config.author_class_name = "User"

  # Limit the author selector with a model scope or a proc receiving the class.
  # Default: nil (all records)
  # config.author_scope = :authors
  # config.author_scope = ->(klass) { klass.where(active: true) }

  # Method used to display authors. Default: :name
  # config.author_display_method = :full_name

  # Controller method that returns the current author. Default: :current_user
  # config.current_author_method = :current_user

  # Proc alternative for Current/session-based identity. When set, this takes
  # precedence over current_author_method. Default: nil
  # config.current_author_proc = -> { Current.user }

  # === CMS Blocks ===

  # Content groups, text/image blocks, helpers, version history, and transfer
  # tools. Enabled for new installations.
  config.enable_cms

  # Right-click editing on public pages. This must authorize every request and
  # also requires `import "railspress"` and `yield :head` in the public layout.
  # Default: nil (disabled)
  # config.inline_editing_check = ->(context) {
  #   context.controller.current_user&.admin?
  # }

  # === Image Contexts ===

  # Focal-point crop contexts. Defaults: hero (16:9), card (4:3), thumb (1:1).
  # Add, remove, or replace contexts as needed:
  # config.add_image_context :portrait, aspect: [3, 4], label: "Portrait", sizes: [900]
  # config.remove_image_context :thumb
  # config.image_contexts = {
  #   hero: { aspect: [16, 9], label: "Hero", sizes: [1920, 1280] }
  # }

  # === Entities (opt-in per model) ===

  # Register host models that include Railspress::Entity. Symbols and strings
  # are reload-safe and preferred over class constants.
  # config.register_entity :project
  # config.register_entity :case_study, label: "Client Work"

  # Fallback entity index columns. Missing columns are ignored.
  # Default: %i[id title name created_at]
  # config.default_index_columns = %i[id title name created_at]

  # === Agents & API (opt-in) ===

  # Bearer-authenticated API endpoints and admin API-key management. Requires
  # all three Active Record Encryption credentials. Generate a snippet with:
  #   bin/rails db:encryption:init
  # RailsPress never writes these secrets.
  # config.enable_api
  # API controllers do not inherit ApplicationController and always enforce
  # their own bearer-token authentication.

  # Canonical URL used in generated API and agent instructions. Falls back to
  # Rails default_url_options and then the current request. Default: nil
  # config.public_base_url = "https://blog.example.com"
end
