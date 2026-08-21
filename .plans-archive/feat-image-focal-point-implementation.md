---
title: "Image Focal Point System Implementation Plan"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Polymorphic focal points, contexts, crop/upload/focal overrides, editor UI, API, entities, CMS integration, and specs are present."
---

# feat: Image Focal Point System - Implementation Plan

**Date**: 2025-01-05 (Updated after implementation)
**Status**: Phase 1 & 2 Complete, Phase 3 Partial
**Complexity**: Medium (3 phases)
**Documentation**: `docs/image-focal-point-system.md`

---

## Current State Summary

### Completed
- [x] **Polymorphic `railspress_focal_points` table** - Stores focal points for any model
- [x] **`Railspress::FocalPoint` model** - Validation, helpers, polymorphic association
- [x] **`HasFocalPoint` concern** - `has_focal_point :attachment_name` macro with auto-build
- [x] **Configuration** - `enable_post_images`, `enable_focal_points`, `image_contexts`
- [x] **Stimulus controllers** - `focal_point_controller`, `dropzone_controller`, `crop_controller`
- [x] **Admin UI partials** - `_image_section`, `_focal_point_editor`, `_dropzone`
- [x] **Nested attributes** - Form integration with `fields_for`
- [x] **Tests** - Full spec coverage for concern and model
- [x] **Documentation** - `docs/image-focal-point-system.md`

### Not Complete (Phase 3 Remaining)
- [ ] **Crop dialog HTML** - `<dialog>` element with Cropper.js integration
- [ ] **Upload override dialog** - Per-context custom image upload
- [ ] **Wire up "Custom Crop" button** - Opens crop dialog, saves region to overrides
- [ ] **Wire up "Upload" button** - Opens upload dialog, saves blob_signed_id
- [ ] **Wire up "Use Focal" button** - Clears override for context

---

## Architecture (Final)

```
┌─────────────────────────────────────────────────────────────────┐
│                   Polymorphic Focal Points Table                 │
├─────────────────────────────────────────────────────────────────┤
│  railspress_focal_points                                         │
│    - record_type, record_id (polymorphic)                       │
│    - attachment_name (string)                                    │
│    - focal_x, focal_y (decimal 0.0-1.0)                         │
│    - overrides (JSON)                                            │
│                                                                  │
│  Works for: Post, Project, any model with HasFocalPoint         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Model Integration                           │
├─────────────────────────────────────────────────────────────────┤
│  class Post < ApplicationRecord                                  │
│    include Railspress::HasFocalPoint                             │
│    has_one_attached :header_image                                │
│    has_focal_point :header_image  # Creates association          │
│  end                                                             │
│                                                                  │
│  # Host app entities - no migration needed!                      │
│  class Project < ApplicationRecord                               │
│    include Railspress::Entity                                    │
│    include Railspress::HasFocalPoint                             │
│    has_one_attached :cover_image                                 │
│    has_focal_point :cover_image                                  │
│  end                                                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Model API                                  │
├─────────────────────────────────────────────────────────────────┤
│  post.focal_point(:header_image)      # => { x: 0.3, y: 0.7 }   │
│  post.focal_point_css(:header_image)  # => "object-position:..."│
│  post.image_for(:hero, :header_image) # => attachment or blob   │
│  post.image_css_for(:hero, :header_image) # => CSS for context  │
│  post.header_image_focal_point        # => FocalPoint record    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema (Implemented)

```ruby
# db/migrate/20250105000002_create_railspress_focal_points.rb
class CreateRailspressFocalPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_focal_points do |t|
      t.references :record, polymorphic: true, null: false, index: false
      t.string :attachment_name, null: false
      t.decimal :focal_x, precision: 5, scale: 4, default: 0.5, null: false
      t.decimal :focal_y, precision: 5, scale: 4, default: 0.5, null: false
      t.json :overrides, default: {}
      t.timestamps
    end

    add_index :railspress_focal_points,
              [:record_type, :record_id, :attachment_name],
              unique: true,
              name: "idx_focal_points_record_attachment"
  end
end
```

---

## Files Created/Modified

### Models
- `app/models/railspress/focal_point.rb` - NEW
- `app/models/concerns/railspress/has_focal_point.rb` - REFACTORED (polymorphic)

### Configuration
- `lib/railspress.rb` - UPDATED (`enable_post_images`, `enable_focal_points`)

### JavaScript
- `app/javascript/railspress/controllers/focal_point_controller.js` - NEW
- `app/javascript/railspress/controllers/dropzone_controller.js` - NEW
- `app/javascript/railspress/controllers/crop_controller.js` - NEW
- `app/javascript/railspress/controllers/index.js` - NEW
- `config/importmap.rb` - NEW

### Views
- `app/views/railspress/admin/shared/_image_section.html.erb` - NEW
- `app/views/railspress/admin/shared/_focal_point_editor.html.erb` - NEW
- `app/views/railspress/admin/shared/_dropzone.html.erb` - NEW

### Styles
- `app/assets/stylesheets/railspress/focal_point.css` - NEW

### Tests
- `spec/models/concerns/railspress/has_focal_point_spec.rb` - NEW
- `spec/fixtures/railspress/focal_points.yml` - NEW

### Documentation
- `docs/image-focal-point-system.md` - NEW

---

## Phase 3 Remaining Work

### 3.1 Crop Dialog Partial

**File to create**: `app/views/railspress/admin/shared/_crop_dialog.html.erb`

```erb
<dialog id="rp-crop-dialog" class="rp-dialog"
        data-controller="railspress--crop">
  <div class="rp-dialog__header">
    <span class="rp-dialog__title">Custom Crop: <span data-crop-context-label></span></span>
    <button type="button" class="rp-dialog__close"
            data-action="click->railspress--crop#cancel">
      &times;
    </button>
  </div>

  <div class="rp-dialog__body">
    <img data-railspress--crop-target="image" class="rp-crop__image">
  </div>

  <div class="rp-dialog__footer">
    <button type="button" class="rp-btn rp-btn--secondary"
            data-action="click->railspress--crop#cancel">
      Cancel
    </button>
    <button type="button" class="rp-btn rp-btn--primary"
            data-action="click->railspress--crop#apply">
      Apply Crop
    </button>
  </div>
</dialog>
```

### 3.2 Wire Up Context Override Buttons

In `_image_section.html.erb`, the Advanced section has placeholder buttons:

```erb
<%# Current (not working) %>
<button type="button" class="rp-btn rp-btn--outline rp-btn--sm">
  Custom Crop
</button>

<%# Needs to be %>
<button type="button" class="rp-btn rp-btn--outline rp-btn--sm"
        data-action="click->railspress--image-section#openCropDialog"
        data-context="<%= name %>"
        data-aspect-ratio="<%= config[:aspect][0].to_f / config[:aspect][1] %>">
  Custom Crop
</button>
```

### 3.3 Image Section Controller

**File to create**: `app/javascript/railspress/controllers/image_section_controller.js`

This controller coordinates between:
- Opening crop/upload dialogs
- Saving override data to hidden inputs
- Updating the preview when overrides change

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overridesInput", "cropDialog", "uploadDialog"]
  static values = {
    overrides: { type: Object, default: {} },
    imageSrc: String
  }

  openCropDialog(event) {
    const context = event.currentTarget.dataset.context
    const aspectRatio = parseFloat(event.currentTarget.dataset.aspectRatio)

    const dialog = document.getElementById("rp-crop-dialog")
    const cropController = this.application.getControllerForElementAndIdentifier(
      dialog, "railspress--crop"
    )

    cropController.srcValue = this.imageSrcValue
    cropController.aspectRatioValue = aspectRatio
    cropController.open()

    // Listen for apply event
    dialog.addEventListener("railspress--crop:apply", (e) => {
      this.setOverride(context, {
        type: "crop",
        region: e.detail.region
      })
    }, { once: true })
  }

  openUploadDialog(event) {
    const context = event.currentTarget.dataset.context
    // TODO: Implement upload dialog
  }

  useFocalPoint(event) {
    const context = event.currentTarget.dataset.context
    this.setOverride(context, { type: "focal" })
  }

  setOverride(context, data) {
    this.overridesValue = {
      ...this.overridesValue,
      [context]: data
    }
    this.overridesInputTarget.value = JSON.stringify(this.overridesValue)
    this.dispatch("override-changed", { detail: { context, data } })
  }
}
```

### 3.4 Update Controller Permits

The overrides JSON needs to be permitted. Currently we permit nested focal point attributes but need to handle the overrides JSON:

```ruby
# In posts_controller.rb
def post_params
  # ... existing ...
  if Railspress.focal_points_enabled?
    permitted.push(
      header_image_focal_point_attributes: [:focal_x, :focal_y, :overrides]
    )
  end
end
```

The `overrides` attribute is already permitted but needs the form to send it correctly.

---

## Acceptance Criteria

### Phase 1 (Complete)
- [x] Migration creates polymorphic focal_points table
- [x] HasFocalPoint concern provides `has_focal_point` macro
- [x] Auto-builds focal point association on first access
- [x] `focal_point`, `focal_point_css`, `image_for`, `image_css_for` work
- [x] Validations enforce 0-1 range and valid override types
- [x] Configuration allows enabling focal points and defining contexts
- [x] All tests pass using fixtures

### Phase 2 (Complete)
- [x] Stimulus controllers register with `railspress--` namespace
- [x] Focal point controller handles click, touch, and keyboard input
- [x] Dropzone uses ActiveStorage DirectUpload
- [x] Crop controller wraps Cropper.js (lazy-loaded from CDN)
- [x] Host apps can import via importmap

### Phase 3 (Partial)
- [x] Image section renders with compact/expanded states
- [x] `<details>` element handles expand/collapse natively
- [x] Focal point picker updates crosshair and previews in real-time
- [x] Dropzone uploads work
- [ ] Crop dialog opens and saves region to overrides
- [ ] Upload dialog opens and saves blob_signed_id
- [ ] "Use Focal" button clears override
- [ ] Per-context preview updates when override is set

---

## Next Steps

1. **Create crop dialog partial** with native `<dialog>` element
2. **Create image_section_controller.js** to coordinate dialogs and overrides
3. **Wire up buttons** in the Advanced section of `_image_section.html.erb`
4. **Add hidden input** for overrides JSON in the form
5. **Test end-to-end** crop and upload override flows

---

## Key Architectural Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | Polymorphic table | No migrations needed for host app entities |
| Association | `has_one` with scope | Auto-build on access, never nil |
| Nested attributes | `accepts_nested_attributes_for` | Works with Rails forms |
| Config naming | `enable_post_images` | Only affects built-in Post model |
| JS loading | Importmap + CDN for Cropper.js | No bundling required |
| Stimulus classes | Hardcoded `rp-*` classes | Simpler than requiring data attributes |
