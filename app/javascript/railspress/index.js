/**
 * RailsPress - Main Entry Point
 *
 * Import this file to auto-register all RailsPress Stimulus controllers.
 *
 * Usage (one line in your application.js):
 *
 *   import "railspress"
 *
 * That's it! Controllers are auto-registered using window.Stimulus.
 *
 * For manual registration (if you don't use window.Stimulus):
 *
 *   import { register } from "railspress"
 *   import { application } from "./application"
 *   register(application)
 */

// Import Turbo for Turbo Frames support
import "@hotwired/turbo-rails"

import FocalPointController from "railspress/controllers/focal_point_controller"
import DropzoneController from "railspress/controllers/dropzone_controller"
import CropController from "railspress/controllers/crop_controller"
import ImageSectionController from "railspress/controllers/image_section_controller"

// Controller definitions with their identifiers
const controllers = {
  "railspress--focal-point": FocalPointController,
  "railspress--dropzone": DropzoneController,
  "railspress--crop": CropController,
  "railspress--image-section": ImageSectionController
}

/**
 * Register all RailsPress controllers with a Stimulus application.
 * @param {Application} application - The Stimulus application instance
 */
export function register(application) {
  for (const [identifier, controller] of Object.entries(controllers)) {
    application.register(identifier, controller)
  }
}

// Auto-register using window.Stimulus (set by host app's application.js)
// This runs as a side-effect when you `import "railspress"`
if (typeof window !== "undefined" && window.Stimulus) {
  register(window.Stimulus)
}

// Export individual controllers for advanced use cases
export { FocalPointController, DropzoneController, CropController, ImageSectionController }

// Re-export the legacy function for backwards compatibility
export { register as registerRailspressControllers }
