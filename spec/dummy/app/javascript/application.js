import "lexxy"

// Stimulus
import { Application } from "@hotwired/stimulus"
const application = Application.start()
application.debug = false
window.Stimulus = application

// RailsPress - register controllers after Stimulus is ready
import { register } from "railspress"
register(application)
