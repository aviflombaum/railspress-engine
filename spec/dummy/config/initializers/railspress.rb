# frozen_string_literal: true

Railspress.configure do |config|
  config.enable_authors
  config.enable_post_images
  config.enable_post_previews
  config.enable_focal_points
  config.enable_cms
  config.enable_api
  config.author_display_method = :email_address
  config.current_admin_proc = -> {
    User.first || User.create!(email_address: "demo@railspress.local")
  }

  # Register entities using string or symbol (reloader-friendly)
  config.register_entity :project

  # Enable inline CMS editing (always on for demo — no auth in dummy app)
  config.inline_editing_check = ->(_context) { true }
end
