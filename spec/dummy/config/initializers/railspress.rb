Railspress.configure do |config|
  config.enable_authors
  config.enable_post_images
  config.enable_focal_points

  # Register entities using string or symbol (reloader-friendly)
  config.register_entity :project
end
