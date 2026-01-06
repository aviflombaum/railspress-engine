import { Controller } from "@hotwired/stimulus"

/**
 * Image Section Controller
 *
 * Handles expand/collapse transitions for the image section.
 * Uses CSS animations for smooth transitions without server round-trips.
 *
 * Usage:
 *   <div data-controller="rp-image-section"
 *        data-rp-image-section-expanded-value="false">
 *
 *     <div data-rp-image-section-target="compact"
 *          data-action="click->rp-image-section#expand">
 *       <!-- compact view -->
 *     </div>
 *
 *     <div data-rp-image-section-target="editor" hidden>
 *       <!-- expanded editor -->
 *       <button data-action="rp-image-section#collapse">Done</button>
 *     </div>
 *   </div>
 */
export default class extends Controller {
  static targets = ["compact", "editor", "editButton"]

  static values = {
    expanded: { type: Boolean, default: false }
  }

  connect() {
    // Sync UI with initial state
    this.updateUI()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.updateUI()
  }

  expand() {
    if (this.expandedValue) return
    this.expandedValue = true
    this.updateUI()
  }

  collapse() {
    if (!this.expandedValue) return
    this.expandedValue = false
    this.updateUI()
  }

  updateUI() {
    if (this.expandedValue) {
      this.showEditor()
    } else {
      this.showCompact()
    }
    this.updateButtonText()
  }

  showEditor() {
    if (this.hasCompactTarget) {
      this.compactTarget.hidden = true
    }
    if (this.hasEditorTarget) {
      this.editorTarget.hidden = false
      this.editorTarget.classList.add("rp-image-section-v2__editor--entering")
      // Remove animation class after animation completes
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.editorTarget.classList.remove("rp-image-section-v2__editor--entering")
        })
      })
    }
    this.element.classList.add("rp-image-section-v2--expanded")
  }

  showCompact() {
    if (this.hasEditorTarget) {
      this.editorTarget.hidden = true
    }
    if (this.hasCompactTarget) {
      this.compactTarget.hidden = false
    }
    this.element.classList.remove("rp-image-section-v2--expanded")
  }

  updateButtonText() {
    if (this.hasEditButtonTarget) {
      this.editButtonTarget.textContent = this.expandedValue ? "Collapse" : "Edit"
    }
  }
}
