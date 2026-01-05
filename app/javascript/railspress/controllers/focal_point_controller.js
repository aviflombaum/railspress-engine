import { Controller } from "@hotwired/stimulus"

/**
 * Focal Point Picker Controller
 *
 * Allows users to click on an image to set the focal point (the most
 * important part of the image) for smart cropping in different contexts.
 *
 * Usage:
 *   <div data-controller="railspress--focal-point"
 *        data-railspress--focal-point-x-value="0.5"
 *        data-railspress--focal-point-y-value="0.5">
 *
 *     <div data-action="click->railspress--focal-point#pick">
 *       <img data-railspress--focal-point-target="image">
 *       <div data-railspress--focal-point-target="crosshair"></div>
 *     </div>
 *
 *     <input type="hidden" data-railspress--focal-point-target="xInput">
 *     <input type="hidden" data-railspress--focal-point-target="yInput">
 *
 *     <img data-railspress--focal-point-target="preview">
 *   </div>
 */
export default class extends Controller {
  static targets = ["image", "crosshair", "xInput", "yInput", "coordsDisplay", "preview"]

  static values = {
    x: { type: Number, default: 0.5 },
    y: { type: Number, default: 0.5 }
  }

  connect() {
    this.updateUI()
  }

  pick(event) {
    event.preventDefault()
    const rect = this.imageTarget.getBoundingClientRect()
    this.xValue = this.clamp((event.clientX - rect.left) / rect.width)
    this.yValue = this.clamp((event.clientY - rect.top) / rect.height)
    this.updateUI()
    this.dispatch("change", { detail: { x: this.xValue, y: this.yValue } })
  }

  touch(event) {
    if (event.touches.length !== 1) return
    event.preventDefault()
    const touch = event.touches[0]
    const rect = this.imageTarget.getBoundingClientRect()
    this.xValue = this.clamp((touch.clientX - rect.left) / rect.width)
    this.yValue = this.clamp((touch.clientY - rect.top) / rect.height)
    this.updateUI()
    this.dispatch("change", { detail: { x: this.xValue, y: this.yValue } })
  }

  reset() {
    this.xValue = 0.5
    this.yValue = 0.5
    this.updateUI()
    this.dispatch("reset")
  }

  keydown(event) {
    const step = event.shiftKey ? 0.1 : 0.01
    let handled = true

    switch (event.key) {
      case "ArrowLeft":
        this.xValue = this.clamp(this.xValue - step)
        break
      case "ArrowRight":
        this.xValue = this.clamp(this.xValue + step)
        break
      case "ArrowUp":
        this.yValue = this.clamp(this.yValue - step)
        break
      case "ArrowDown":
        this.yValue = this.clamp(this.yValue + step)
        break
      default:
        handled = false
    }

    if (handled) {
      event.preventDefault()
      this.updateUI()
      this.dispatch("change", { detail: { x: this.xValue, y: this.yValue } })
    }
  }

  updateUI() {
    this.updateCrosshair()
    this.updateInputs()
    this.updatePreviews()
    this.updateCoordsDisplay()
  }

  updateCrosshair() {
    if (!this.hasCrosshairTarget) return
    this.crosshairTarget.style.left = `${this.xValue * 100}%`
    this.crosshairTarget.style.top = `${this.yValue * 100}%`
  }

  updateInputs() {
    if (this.hasXInputTarget) this.xInputTarget.value = this.xValue.toFixed(4)
    if (this.hasYInputTarget) this.yInputTarget.value = this.yValue.toFixed(4)
  }

  updatePreviews() {
    const position = `${this.xValue * 100}% ${this.yValue * 100}%`
    this.previewTargets.forEach(el => el.style.objectPosition = position)
  }

  updateCoordsDisplay() {
    if (!this.hasCoordsDisplayTarget) return
    this.coordsDisplayTarget.textContent =
      `${Math.round(this.xValue * 100)}%, ${Math.round(this.yValue * 100)}%`
  }

  clamp(value) {
    return Math.max(0, Math.min(1, value))
  }
}
