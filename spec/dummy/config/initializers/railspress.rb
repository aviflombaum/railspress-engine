Railspress.configure do |config|
  config.enable_authors
  config.enable_header_images

  # Register entities using string or symbol (reloader-friendly)
  config.register_entity :project
end
