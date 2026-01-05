# RailsPress Engine Importmap Configuration
#
# This file is automatically loaded by host applications using importmap-rails.
# Controllers are pinned under the "railspress/controllers" namespace.

pin_all_from Railspress::Engine.root.join("app/javascript/railspress/controllers"),
             under: "railspress/controllers",
             to: "railspress/controllers"
