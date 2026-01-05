import "lexxy"

// Stimulus
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.debug = false
window.Stimulus = application

// RailsPress controllers
import FocalPointController from "railspress/controllers/focal_point_controller"
import DropzoneController from "railspress/controllers/dropzone_controller"
import CropController from "railspress/controllers/crop_controller"

application.register("railspress--focal-point", FocalPointController)
application.register("railspress--dropzone", DropzoneController)
application.register("railspress--crop", CropController)
