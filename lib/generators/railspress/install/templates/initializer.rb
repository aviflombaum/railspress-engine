# frozen_string_literal: true

Railspress.configure do |config|
  # === Blog Features (always available) ===

  # Author tracking for posts and content elements.
  # Uncomment to enable:
  # config.enable_authors
  # config.author_class_name = "User"
  # config.author_scope = :admins
  # config.current_author_method = :current_user
  # config.current_author_proc = -> { Current.user }

  # Header images for Posts
  # Uncomment to enable:
  # config.enable_post_images
  # config.enable_focal_points

  # === CMS Content Elements (opt-in) ===
  # Adds content groups, content elements, and the cms_element/cms_value
  # view helpers for managing structured content on your site.
  # Image elements support dropzone upload and focal points when
  # enable_focal_points is also active.
  # See docs/CONFIGURING.md for details.
  # Uncomment to enable:
  # config.enable_cms

  # === Inline CMS Editing (requires enable_cms) ===
  # Right-click editing of CMS content on public pages.
  # Also requires: import "railspress" in your application.js
  # and yield :head in your layout. See docs/INLINE_EDITING.md.
  # Uncomment to enable:
  # config.inline_editing_check = ->(context) {
  #   context.controller.current_user&.admin?
  # }

  # === Admin Authentication ===
  # RailsPress browser controllers inherit your host ApplicationController.
  # Set the host method that protects /railspress/admin. Leave unset only when
  # an inherited ApplicationController callback already protects the admin UI.
  # config.admin_authentication_method = :require_admin!
  # Set the host method that returns the signed-in administrator. The default
  # is :current_user; a proc supports Current/session based lookup instead.
  # config.current_admin_method = :current_user
  # config.current_admin_proc = -> { Current.user }

  # === API (opt-in) ===
  # Enables API endpoints under /railspress/api/v1 and admin API key management.
  # Requires all three Active Record Encryption credentials in the host app.
  # Generate a credentials snippet (RailsPress never writes these secrets):
  #   bin/rails db:encryption:init
  # Uncomment to enable:
  # config.enable_api
  # The current-admin strategy above audits API key management actions.
  # API controllers do not inherit ApplicationController and always use their
  # own bearer-token authentication.
  # Optional: force a canonical public base URL in generated API instructions.
  # Falls back to Rails.application.routes.default_url_options, then request host.
  # config.public_base_url = "https://blog.example.com"
end
