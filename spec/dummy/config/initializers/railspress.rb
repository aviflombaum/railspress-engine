Railspress.configure do |config|
  config.enable_authors
  config.enable_post_images
  config.enable_focal_points
  config.enable_cms
  config.author_display_method = :email_address

  # Enable API in dummy app outside test environment.
  # Specs reset Railspress configuration between examples, so they opt in explicitly.
  unless Rails.env.test?
    config.enable_api
    config.current_api_actor_proc = -> {
      User.first || User.create!(email_address: "demo@railspress.local")
    }
  end

  # Register entities using string or symbol (reloader-friendly)
  config.register_entity :project

  # Enable inline CMS editing (always on for demo — no auth in dummy app)
  config.inline_editing_check = ->(_context) { true }
end
