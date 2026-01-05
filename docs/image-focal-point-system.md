# Image Focal Point System

RailsPress includes a flexible image management system with focal point selection and per-context overrides. This allows content editors to control how images are cropped across different display contexts (hero banners, cards, thumbnails, etc.).

## Overview

The system has three layers:

1. **Global Configuration** - Define image contexts (aspect ratios) at the application level
2. **Per-Image Focal Points** - Set where the "important part" of each image is
3. **Per-Context Overrides** - Optionally use custom crops or different images for specific contexts

## Quick Start

### 1. Enable the Feature

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_post_images    # Enables header_image on Post model
  config.enable_focal_points   # Enables focal point editing UI
end
```

### 2. Run Migrations

```bash
rails railspress:install:migrations
rails db:migrate
```

This creates the `railspress_focal_points` table for storing focal point data.

### 3. Use in Views

```erb
<%# In your view %>
<%= image_tag url_for(@post.header_image.variant(resize_to_limit: [800, 600])),
      style: @post.focal_point_css(:header_image) %>
```

## Configuration

### Image Contexts

Define the aspect ratios your site uses:

```ruby
Railspress.configure do |config|
  # Default contexts (you can customize these)
  config.image_contexts = {
    hero:  { aspect: [16, 9], label: "Hero Banner", sizes: [1920, 1280] },
    card:  { aspect: [4, 3],  label: "Card",        sizes: [800, 400] },
    thumb: { aspect: [1, 1],  label: "Thumbnail",   sizes: [200] }
  }

  # Or add individual contexts
  config.add_image_context :wide, aspect: [21, 9], label: "Ultra Wide"
  config.add_image_context :portrait, aspect: [3, 4], label: "Portrait"
end
```

## Database Schema

The focal point data is stored in a polymorphic table:

```ruby
create_table :railspress_focal_points do |t|
  t.references :record, polymorphic: true, null: false
  t.string :attachment_name, null: false
  t.decimal :focal_x, precision: 5, scale: 4, default: 0.5
  t.decimal :focal_y, precision: 5, scale: 4, default: 0.5
  t.json :overrides, default: {}
  t.timestamps
end
```

- `record` - Polymorphic reference to the parent model (Post, Project, etc.)
- `attachment_name` - Which attachment this focal point is for (e.g., "header_image")
- `focal_x`, `focal_y` - Coordinates from 0.0 to 1.0 (0.5, 0.5 = center)
- `overrides` - JSON hash of per-context overrides

## Adding Focal Points to Your Models

### For RailsPress Posts

Posts automatically have focal points when `enable_post_images` and `enable_focal_points` are both enabled.

### For Custom Models (Entities)

Include the `HasFocalPoint` concern and declare which attachments support focal points:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::HasFocalPoint

  has_one_attached :cover_image
  has_one_attached :banner_image

  has_focal_point :cover_image
  has_focal_point :banner_image
end
```

That's it! No migrations needed on your model - the polymorphic `railspress_focal_points` table stores all focal point data.

## Model API

### Reading Focal Points

```ruby
post = Post.find(1)

# Get focal point coordinates (returns hash)
post.focal_point(:header_image)
# => { x: 0.3, y: 0.7 }

# Get CSS for object-position
post.focal_point_css(:header_image)
# => "object-position: 30.0% 70.0%"

# Check if focal point is set (not center)
post.has_focal_point?(:header_image)
# => true
```

### Context-Aware Image Selection

```ruby
# Get the image for a specific context
# Returns the original attachment, or an uploaded override blob
image = post.image_for(:hero, :header_image)

# Get CSS for a specific context
# Handles focal points, crops, and uploads appropriately
css = post.image_css_for(:hero, :header_image)
```

### Per-Context Overrides

Overrides allow different treatments per context:

```ruby
# Check if context has a custom override
post.has_image_override?(:hero, :header_image)
# => true/false

# Get override details
post.image_override(:hero, :header_image)
# => { type: "crop", region: { x: 0.1, y: 0.2, width: 0.6, height: 0.5 } }

# Set an override
post.set_image_override(:hero, {
  type: "crop",
  region: { x: 0.1, y: 0.2, width: 0.6, height: 0.5 }
}, :header_image)

# Clear override (revert to using focal point)
post.clear_image_override(:hero, :header_image)
```

### Override Types

| Type | Description |
|------|-------------|
| `focal` | Use the global focal point (default) |
| `crop` | Use a custom crop region for this context |
| `upload` | Use a completely different image for this context |

## View Helpers

### Basic Usage

```erb
<%# Apply focal point CSS to an image %>
<%= image_tag url_for(@post.header_image),
      style: @post.focal_point_css(:header_image),
      class: "object-cover w-full h-64" %>
```

### Context-Aware Usage

```erb
<%# Hero section - might use focal point or custom crop %>
<div class="hero" style="aspect-ratio: 16/9;">
  <% image = @post.image_for(:hero, :header_image) %>
  <% if image.respond_to?(:variant) %>
    <%= image_tag url_for(image.variant(resize_to_limit: [1920, 1080])),
          style: @post.image_css_for(:hero, :header_image),
          class: "object-cover w-full h-full" %>
  <% elsif image.respond_to?(:url) %>
    <%= image_tag url_for(image),
          class: "object-cover w-full h-full" %>
  <% end %>
</div>
```

### Card Component Example

```erb
<%# Card with 4:3 aspect ratio %>
<article class="card">
  <div class="card-image" style="aspect-ratio: 4/3;">
    <%= image_tag url_for(@post.header_image.variant(resize_to_limit: [800, 600])),
          style: @post.image_css_for(:card, :header_image),
          class: "object-cover w-full h-full" %>
  </div>
  <div class="card-body">
    <h3><%= @post.title %></h3>
  </div>
</article>
```

## Admin UI

### Image Section Partial

Use the provided partial in your admin forms:

```erb
<%= form_with model: [:admin, @post] do |form| %>
  <%# ... other fields ... %>

  <% if Railspress.focal_points_enabled? %>
    <%= render "railspress/admin/shared/image_section",
          form: form,
          record: @post,
          attachment_name: :header_image,
          label: "Featured Image" %>
  <% end %>
<% end %>
```

### Partial Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `form` | FormBuilder | required | Rails form builder |
| `record` | Model | required | Record with HasFocalPoint |
| `attachment_name` | Symbol | required | Attachment name (e.g., `:header_image`) |
| `label` | String | "Main Image" | Section label |
| `contexts` | Hash | `Railspress.image_contexts` | Context configs for previews |
| `show_advanced` | Boolean | false | Show per-context override UI |

### Controller Setup

Permit nested focal point attributes:

```ruby
class Admin::PostsController < ApplicationController
  def post_params
    params.require(:post).permit(
      :title, :content, :header_image, :remove_header_image,
      header_image_focal_point_attributes: [:focal_x, :focal_y, :overrides]
    )
  end
end
```

## Stimulus Controllers

The admin UI uses three Stimulus controllers:

### Focal Point Controller

Handles click-to-set focal point interaction:

```html
<div data-controller="railspress--focal-point"
     data-railspress--focal-point-x-value="0.5"
     data-railspress--focal-point-y-value="0.5">

  <img data-railspress--focal-point-target="image"
       data-action="click->railspress--focal-point#pick">

  <div data-railspress--focal-point-target="crosshair"></div>

  <input type="hidden" data-railspress--focal-point-target="xInput">
  <input type="hidden" data-railspress--focal-point-target="yInput">

  <img data-railspress--focal-point-target="preview">
</div>
```

### Dropzone Controller

Handles drag-and-drop file uploads with DirectUpload:

```html
<div data-controller="railspress--dropzone"
     data-railspress--dropzone-url-value="/rails/active_storage/direct_uploads"
     data-action="drop->railspress--dropzone#drop
                  dragover->railspress--dropzone#dragover
                  dragleave->railspress--dropzone#dragleave">

  <input type="file" data-railspress--dropzone-target="input">
  <input type="hidden" data-railspress--dropzone-target="signedId" name="post[header_image]">

  <div data-railspress--dropzone-target="dropArea">Drop here</div>
  <div data-railspress--dropzone-target="preview" hidden>
    <img data-railspress--dropzone-target="previewImage">
  </div>
  <div data-railspress--dropzone-target="progress" hidden>
    <div data-railspress--dropzone-target="progressBar"></div>
  </div>
</div>
```

### Crop Controller

Handles custom crop region selection using Cropper.js (lazy-loaded from CDN).

## CSS Classes

The system uses BEM-style classes with `rp-` prefix:

```css
/* Dropzone states */
.rp-dropzone--dragging { }
.rp-dropzone--uploading { }
.rp-dropzone--complete { }
.rp-dropzone--error { }

/* Focal point editor */
.rp-focal-editor { }
.rp-focal-editor__crosshair { }
.rp-focal-editor__preview { }

/* Image section */
.rp-image-section { }
.rp-image-section__compact { }
.rp-image-section__editor { }
```

## How It Works

### Display-Time Cropping

The focal point system uses CSS `object-position` for display-time cropping:

```css
.image-container {
  aspect-ratio: 16 / 9;
  overflow: hidden;
}

.image-container img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 30% 70%; /* Focal point at x=0.3, y=0.7 */
}
```

This means:
- Original images are never destructively cropped
- The same image works across all aspect ratios
- Focal point changes take effect immediately (no re-processing)

### Crop Region Calculation

For crop overrides, the system calculates `object-position` from the crop region:

```
x_position = (region.x + region.width / 2) * 100%
y_position = (region.y + region.height / 2) * 100%
```

## Architecture Decisions

### Why Polymorphic Table?

Instead of adding columns to each model:

1. **No migrations needed** for host app models
2. **Consistent pattern** across all entity types
3. **Mirrors ActionText** approach (`action_text_rich_texts`)
4. **Single table** for all focal point data

### Why Display-Time Cropping?

Instead of generating pre-cropped variants:

1. **Immediate updates** - No waiting for image processing
2. **Single source** - One image serves all contexts
3. **Reversible** - Change focal point anytime
4. **Storage efficient** - No duplicate variants per context

### Why Optional Overrides?

The focal point works for most cases, but sometimes you need:

- **Custom crops** for specific contexts (tighter framing for thumbnails)
- **Different images** entirely (simplified version for small sizes)

## Troubleshooting

### Focal Point Not Saving

Ensure nested attributes are permitted in your controller:

```ruby
permitted.push(header_image_focal_point_attributes: [:focal_x, :focal_y, :overrides])
```

### Stimulus Controllers Not Loading

Check that your importmap includes the RailsPress controllers and `@hotwired/stimulus`:

```ruby
# config/importmap.rb
pin "@hotwired/stimulus", to: "https://ga.jspm.io/npm:@hotwired/stimulus@3.2.2/dist/stimulus.js"
```

### Images Not Cropping Correctly

Ensure you're using `object-fit: cover` on the image:

```css
img {
  object-fit: cover;
  width: 100%;
  height: 100%;
}
```

## Migration from Direct Columns

If you previously had focal point columns directly on your model:

```ruby
# Migration to move data to polymorphic table
class MigrateFocalPointsToPolymorphicTable < ActiveRecord::Migration[8.0]
  def up
    Post.find_each do |post|
      next unless post.header_image.attached?

      Railspress::FocalPoint.create!(
        record: post,
        attachment_name: "header_image",
        focal_x: post.read_attribute(:header_image_focal_x) || 0.5,
        focal_y: post.read_attribute(:header_image_focal_y) || 0.5,
        overrides: post.read_attribute(:header_image_overrides) || {}
      )
    end

    remove_column :railspress_posts, :header_image_focal_x
    remove_column :railspress_posts, :header_image_focal_y
    remove_column :railspress_posts, :header_image_overrides
  end
end
```
