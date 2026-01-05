/**
 * RailsPress Stimulus Controllers
 *
 * Registers all RailsPress controllers with a Stimulus application.
 *
 * Usage in host app:
 *
 *   // In application.js or wherever you configure Stimulus
 *   import { Application } from "@hotwired/stimulus"
 *   import { registerRailspressControllers } from "railspress/controllers"
 *
 *   const application = Application.start()
 *   registerRailspressControllers(application)
 *
 * Or register controllers individually:
 *
 *   import FocalPointController from "railspress/controllers/focal_point_controller"
 *   application.register("railspress--focal-point", FocalPointController)
 */

import FocalPointController from "./focal_point_controller"
import DropzoneController from "./dropzone_controller"
import CropController from "./crop_controller"

// Export individual controllers
export { FocalPointController, DropzoneController, CropController }

// Export registration function for convenience
export function registerRailspressControllers(application) {
  application.register("railspress--focal-point", FocalPointController)
  application.register("railspress--dropzone", DropzoneController)
  application.register("railspress--crop", CropController)
}
