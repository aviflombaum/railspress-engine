import { Controller } from "@hotwired/stimulus"

/**
 * Crop Controller
 *
 * Wraps Cropper.js for image cropping. Lazy-loads Cropper.js from CDN
 * when first needed to avoid bundling the library.
 *
 * Usage:
 *   <dialog data-controller="railspress--crop"
 *           data-railspress--crop-aspect-ratio-value="1.778"
 *           data-railspress--crop-src-value="/path/to/image.jpg">
 *
 *     <img data-railspress--crop-target="image">
 *
 *     <button data-action="railspress--crop#apply">Apply Crop</button>
 *     <button data-action="railspress--crop#cancel">Cancel</button>
 *     <button data-action="railspress--crop#reset">Reset</button>
 *   </dialog>
 *
 * Events:
 *   - railspress--crop:apply  - Dispatched with { region: { x, y, width, height } }
 *   - railspress--crop:cancel - Dispatched when crop is cancelled
 */
export default class extends Controller {
  static targets = ["image", "preview"]

  static values = {
    src: String,
    aspectRatio: { type: Number, default: 0 }, // 0 = free aspect ratio
    viewMode: { type: Number, default: 1 },
    minWidth: { type: Number, default: 100 },
    minHeight: { type: Number, default: 100 },
    cropperUrl: {
      type: String,
      default: "https://cdn.jsdelivr.net/npm/cropperjs@1.6.2/dist/cropper.min.js"
    },
    cropperCssUrl: {
      type: String,
      default: "https://cdn.jsdelivr.net/npm/cropperjs@1.6.2/dist/cropper.min.css"
    }
  }

  cropper = null
  cropperLoaded = false

  connect() {
    // If this is a dialog element, set up show/close handlers
    if (this.element.tagName === "DIALOG") {
      this.element.addEventListener("close", this.handleClose.bind(this))
    }
  }

  disconnect() {
    this.destroyCropper()
  }

  // Opens the crop dialog and initializes cropper
  async open(imageSrc = null) {
    if (imageSrc) {
      this.srcValue = imageSrc
    }

    // Show dialog if it's a dialog element
    if (this.element.tagName === "DIALOG" && !this.element.open) {
      this.element.showModal()
    }

    await this.initializeCropper()
  }

  async initializeCropper() {
    // Load Cropper.js if not already loaded
    if (!window.Cropper) {
      await this.loadCropper()
    }

    // Set image source
    if (this.hasImageTarget && this.srcValue) {
      this.imageTarget.src = this.srcValue

      // Wait for image to load
      await new Promise((resolve, reject) => {
        this.imageTarget.onload = resolve
        this.imageTarget.onerror = reject
      })

      // Initialize Cropper
      this.destroyCropper() // Clean up any existing instance
      this.cropper = new window.Cropper(this.imageTarget, {
        aspectRatio: this.aspectRatioValue || NaN, // NaN = free aspect ratio
        viewMode: this.viewModeValue,
        minCropBoxWidth: this.minWidthValue,
        minCropBoxHeight: this.minHeightValue,
        autoCropArea: 1,
        responsive: true,
        restore: true,
        guides: true,
        center: true,
        highlight: true,
        background: true,
        movable: true,
        rotatable: false,
        scalable: false,
        zoomable: true,
        zoomOnTouch: true,
        zoomOnWheel: true,
        cropBoxMovable: true,
        cropBoxResizable: true,
        toggleDragModeOnDblclick: false
      })
    }
  }

  async loadCropper() {
    if (this.cropperLoaded) return

    // Load CSS
    const link = document.createElement("link")
    link.rel = "stylesheet"
    link.href = this.cropperCssUrlValue
    document.head.appendChild(link)

    // Load JS
    await new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = this.cropperUrlValue
      script.onload = resolve
      script.onerror = reject
      document.head.appendChild(script)
    })

    this.cropperLoaded = true
  }

  apply(event) {
    event?.preventDefault()

    if (!this.cropper) return

    const cropData = this.cropper.getData(true) // true = rounded values
    const imageData = this.cropper.getImageData()

    // Calculate normalized region (0-1 values)
    const region = {
      x: cropData.x / imageData.naturalWidth,
      y: cropData.y / imageData.naturalHeight,
      width: cropData.width / imageData.naturalWidth,
      height: cropData.height / imageData.naturalHeight
    }

    this.dispatch("apply", { detail: { region, cropData, imageData } })
    this.close()
  }

  cancel(event) {
    event?.preventDefault()
    this.dispatch("cancel")
    this.close()
  }

  reset(event) {
    event?.preventDefault()
    if (this.cropper) {
      this.cropper.reset()
    }
  }

  close() {
    if (this.element.tagName === "DIALOG" && this.element.open) {
      this.element.close()
    }
    this.destroyCropper()
  }

  handleClose() {
    this.destroyCropper()
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  // Set aspect ratio dynamically
  setAspectRatio(ratio) {
    this.aspectRatioValue = ratio
    if (this.cropper) {
      this.cropper.setAspectRatio(ratio || NaN)
    }
  }

  // Zoom controls
  zoomIn(event) {
    event?.preventDefault()
    if (this.cropper) {
      this.cropper.zoom(0.1)
    }
  }

  zoomOut(event) {
    event?.preventDefault()
    if (this.cropper) {
      this.cropper.zoom(-0.1)
    }
  }

  // Rotation (if enabled)
  rotateLeft(event) {
    event?.preventDefault()
    if (this.cropper) {
      this.cropper.rotate(-90)
    }
  }

  rotateRight(event) {
    event?.preventDefault()
    if (this.cropper) {
      this.cropper.rotate(90)
    }
  }
}
