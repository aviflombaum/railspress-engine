# frozen_string_literal: true

Railspress.configure do |config|
  # === Blog Features (always available) ===

  # Author tracking for posts and content elements.
  # Uncomment to enable:
  # config.enable_authors
  # config.author_class_name = "User"
  # config.current_author_method = :current_user

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
end
