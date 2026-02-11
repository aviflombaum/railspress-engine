import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["typeSelect", "textFields", "imageFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const isImage = this.typeSelectTarget.value === "image"
    this.textFieldsTarget.style.display = isImage ? "none" : ""
    this.imageFieldsTarget.style.display = isImage ? "" : "none"
  }
}
