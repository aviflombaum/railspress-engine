# RailsPress Engine Importmap Configuration
#
# This file is automatically loaded by host applications using importmap-rails.
#
# Usage in host app (add to app/javascript/application.js):
#
#   import "railspress"
#
# This auto-registers all RailsPress Stimulus controllers.

# Main entry point - auto-registers all controllers
pin "railspress", to: "railspress/index.js"

# Individual controllers (for advanced use cases)
pin_all_from Railspress::Engine.root.join("app/javascript/railspress/controllers"),
             under: "railspress/controllers",
             to: "railspress/controllers"
