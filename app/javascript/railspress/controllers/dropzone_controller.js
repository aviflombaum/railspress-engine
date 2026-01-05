import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

/**
 * Dropzone Controller
 *
 * Handles drag-and-drop file uploads using ActiveStorage DirectUpload.
 * Provides visual feedback during upload and integrates with forms.
 *
 * Usage:
 *   <div data-controller="railspress--dropzone"
 *        data-railspress--dropzone-url-value="/rails/active_storage/direct_uploads"
 *        data-railspress--dropzone-accept-value="image/*"
 *        data-action="drop->railspress--dropzone#drop
 *                     dragover->railspress--dropzone#dragover
 *                     dragleave->railspress--dropzone#dragleave">
 *
 *     <input type="file" data-railspress--dropzone-target="input" class="sr-only">
 *     <input type="hidden" data-railspress--dropzone-target="signedId" name="post[header_image]">
 *
 *     <div data-railspress--dropzone-target="dropArea">
 *       <span data-railspress--dropzone-target="prompt">Drag image here or click to browse</span>
 *     </div>
 *
 *     <div data-railspress--dropzone-target="preview" hidden>
 *       <img data-railspress--dropzone-target="previewImage">
 *       <button data-action="railspress--dropzone#remove">Remove</button>
 *     </div>
 *
 *     <div data-railspress--dropzone-target="progress" hidden>
 *       <div data-railspress--dropzone-target="progressBar"></div>
 *       <span data-railspress--dropzone-target="progressText">0%</span>
 *     </div>
 *
 *     <div data-railspress--dropzone-target="error" hidden></div>
 *   </div>
 */
export default class extends Controller {
  static targets = [
    "input",
    "signedId",
    "dropArea",
    "prompt",
    "preview",
    "previewImage",
    "progress",
    "progressBar",
    "progressText",
    "error"
  ]

  static values = {
    url: { type: String, default: "/rails/active_storage/direct_uploads" },
    accept: { type: String, default: "image/*" },
    maxSize: { type: Number, default: 10 * 1024 * 1024 } // 10MB default
  }

  // Using hardcoded class names for simplicity in engine context
  // Host apps can override via CSS or fork the controller

  connect() {
    this.element.addEventListener("click", this.openFilePicker.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.openFilePicker.bind(this))
  }

  openFilePicker(event) {
    // Don't open if clicking on remove button or preview
    if (event.target.closest("[data-action*='remove']")) return
    if (event.target.closest("button")) return

    this.inputTarget.click()
  }

  dragover(event) {
    event.preventDefault()
    this.element.classList.add("rp-dropzone--dragging")
  }

  dragleave(event) {
    event.preventDefault()
    this.element.classList.remove("rp-dropzone--dragging")
  }

  drop(event) {
    event.preventDefault()
    this.element.classList.remove("rp-dropzone--dragging")

    const files = event.dataTransfer?.files
    if (files?.length > 0) {
      this.handleFile(files[0])
    }
  }

  // Called when file input changes
  change(event) {
    const file = event.target.files?.[0]
    if (file) {
      this.handleFile(file)
    }
  }

  handleFile(file) {
    // Validate file type
    if (!this.isValidType(file)) {
      this.showError(`Invalid file type. Please upload ${this.acceptValue}`)
      return
    }

    // Validate file size
    if (file.size > this.maxSizeValue) {
      const maxMB = Math.round(this.maxSizeValue / 1024 / 1024)
      this.showError(`File too large. Maximum size is ${maxMB}MB`)
      return
    }

    this.hideError()
    this.showPreview(file)
    this.uploadFile(file)
  }

  isValidType(file) {
    if (this.acceptValue === "*" || this.acceptValue === "*/*") return true

    const accepts = this.acceptValue.split(",").map(s => s.trim())
    return accepts.some(accept => {
      if (accept.startsWith(".")) {
        return file.name.toLowerCase().endsWith(accept.toLowerCase())
      }
      if (accept.endsWith("/*")) {
        const baseType = accept.replace("/*", "")
        return file.type.startsWith(baseType)
      }
      return file.type === accept
    })
  }

  showPreview(file) {
    if (!this.hasPreviewTarget) return

    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewImageTarget) {
        this.previewImageTarget.src = e.target.result
      }
      this.previewTarget.hidden = false
      if (this.hasDropAreaTarget) {
        this.dropAreaTarget.hidden = true
      }
    }
    reader.readAsDataURL(file)
  }

  uploadFile(file) {
    this.showProgress()
    this.element.classList.add("rp-dropzone--uploading")

    const upload = new DirectUpload(file, this.urlValue, this)

    upload.create((error, blob) => {
      this.hideProgress()
      this.element.classList.remove("rp-dropzone--uploading")

      if (error) {
        this.showError(`Upload failed: ${error}`)
        this.element.classList.add("rp-dropzone--error")
      } else {
        this.element.classList.add("rp-dropzone--complete")
        if (this.hasSignedIdTarget) {
          this.signedIdTarget.value = blob.signed_id
        }
        this.dispatch("upload", { detail: { blob, signedId: blob.signed_id } })
      }
    })
  }

  // DirectUpload delegate methods
  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", event => this.updateProgress(event))
  }

  updateProgress(event) {
    if (!event.lengthComputable) return

    const percent = Math.round((event.loaded / event.total) * 100)

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
    }
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${percent}%`
    }
  }

  showProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.hidden = false
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = "0%"
      }
      if (this.hasProgressTextTarget) {
        this.progressTextTarget.textContent = "0%"
      }
    }
  }

  hideProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.hidden = true
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.hidden = false
    }
    this.element.classList.add("rp-dropzone--error")
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.hidden = true
    }
    this.element.classList.remove("rp-dropzone--error")
  }

  remove(event) {
    event.preventDefault()
    event.stopPropagation()

    // Clear the signed ID
    if (this.hasSignedIdTarget) {
      this.signedIdTarget.value = ""
    }

    // Clear file input
    if (this.hasInputTarget) {
      this.inputTarget.value = ""
    }

    // Hide preview, show drop area
    if (this.hasPreviewTarget) {
      this.previewTarget.hidden = true
      if (this.hasPreviewImageTarget) {
        this.previewImageTarget.src = ""
      }
    }
    if (this.hasDropAreaTarget) {
      this.dropAreaTarget.hidden = false
    }

    // Reset classes
    this.element.classList.remove("rp-dropzone--complete", "rp-dropzone--error")

    this.hideError()
    this.dispatch("remove")
  }
}
