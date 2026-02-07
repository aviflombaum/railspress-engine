Railspress.configure do |config|
  config.enable_authors
  config.enable_post_images
  config.enable_focal_points

  # Register entities using string or symbol (reloader-friendly)
  config.register_entity :project

  # Enable inline CMS editing (always on for demo — no auth in dummy app)
  config.inline_editing_check = ->(_context) { true }
end
