# Entity System

The Entity system allows you to manage any ActiveRecord model through the RailsPress admin interface without writing custom controllers or views. Define which fields should appear in the CMS, and RailsPress handles the rest.

## Quick Start

### 1. Include the Entity concern in your model

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  include Railspress::Entity

  has_rich_text :body
  has_many_attached :gallery

  # Declare which fields appear in the CMS
  railspress_fields :title, :client, :featured
  railspress_fields :description
  railspress_fields :body
  railspress_fields :gallery, as: :attachments

  # Optional: Custom sidebar label (defaults to pluralized model name)
  railspress_label "Client Projects"

  validates :title, presence: true
end
```

### 2. Register the entity in an initializer

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.register_entity :project
end
```

That's it. Your model now has full CRUD at `/railspress/admin/entities/projects`.

---

## The `railspress_fields` DSL

Declare which model attributes should appear in the admin forms and index table.

### Basic usage (auto-detected types)

```ruby
railspress_fields :title, :description, :published
```

Types are automatically detected from:
1. ActionText associations (`has_rich_text`)
2. ActiveStorage attachments (`has_one_attached`, `has_many_attached`)
3. Database column types

### Explicit type override

```ruby
railspress_fields :body, as: :rich_text
railspress_fields :gallery, as: :attachments
```

### Supported field types

| Type | Detection | Form Input | Index Display |
|------|-----------|------------|---------------|
| `:string` | String columns | Text field | Truncated text |
| `:text` | Text columns | Textarea | Truncated text |
| `:rich_text` | `has_rich_text` | Trix editor | Stripped/truncated |
| `:boolean` | Boolean columns | Checkbox | Yes/No badge |
| `:integer` | Integer columns | Number field | Raw value |
| `:decimal` | Decimal/float columns | Number field (step: any) | Raw value |
| `:datetime` | Datetime columns | Datetime-local picker | Formatted date |
| `:date` | Date columns | Date picker | Formatted date |
| `:attachment` | `has_one_attached` | File input | Attached/None badge |
| `:attachments` | `has_many_attached` | Multiple file input | "N images" badge |
| `:focal_point_image` | `focal_point_image` macro | Image upload + focal picker | Attached/None badge |
| `:list` | Explicit only | Text field (comma-separated) | "N items" badge |
| `:lines` | Explicit only | Textarea (line-separated) | "N items" badge |

### Form layout

Fields are automatically organized into a two-column layout:

- **Main column**: String, text, rich text, and `:lines` fields
- **Sidebar**: Boolean, numeric, date, and `:list` fields in an "Options" section
- **Sidebar**: Each attachment field gets its own section with preview and removal

---

## Array Fields

Store arrays of strings in JSON columns using `:list` and `:lines` field types. These are useful for things like tech stacks, features lists, or highlights.

### Quick Start

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :title, :client
  railspress_fields :tech_stack, as: :list      # Comma-separated input
  railspress_fields :highlights, as: :lines     # Line-separated input
end
```

That's it. Virtual attributes are auto-generated. No extra concerns or boilerplate needed.

### Migration

Use JSON or JSONB columns with array defaults:

```ruby
class AddArrayFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :tech_stack, :jsonb, default: [], null: false
    add_column :projects, :highlights, :jsonb, default: [], null: false
  end
end
```

### Two Field Types

| Type | Input Format | Best For | Deduplicates? |
|------|--------------|----------|---------------|
| `:list` | Comma-separated | Short items (tags, tech names) | Yes |
| `:lines` | One per line | Sentences, paragraphs | No |

### How It Works

When you declare `railspress_fields :tech_stack, as: :list`, RailsPress auto-generates:

```ruby
# Nil guard - always returns array, never nil
def tech_stack
  super || []
end

# Virtual getter: array → comma string (for form population)
def tech_stack_list
  tech_stack.join(", ")
end

# Virtual setter: comma string → array (for form submission)
def tech_stack_list=(value)
  self.tech_stack = value.split(",").map(&:strip).reject(&:blank?).uniq
end
```

For `:lines` fields, the separator is newline instead of comma, and duplicates are preserved.

### Form Behavior

**`:list` fields** render as a single-line text input:
```
Tech Stack: [Ruby, Rails, PostgreSQL, Redis_______]
            Separate items with commas
```

**`:lines` fields** render as a textarea:
```
Highlights:
┌─────────────────────────────────────┐
│ Built API in 2 weeks               │
│ Reduced load time by 50%           │
│ Featured in Ruby Weekly            │
└─────────────────────────────────────┘
Enter one item per line
```

### Display Behavior

**Index view**: Shows item count badge ("3 items")

**Show view**:
- `:list` displays inline: "Ruby, Rails, PostgreSQL"
- `:lines` displays as bullet list

### Input Parsing

**`:list` fields**:
- Split on comma
- Strip whitespace from each item
- Remove empty items
- Deduplicate (preserves first occurrence)

```ruby
project.tech_stack_list = "  Ruby ,, Rails , Ruby  "
project.tech_stack  # => ["Ruby", "Rails"]
```

**`:lines` fields**:
- Split on newline (handles both `\n` and `\r\n`)
- Strip whitespace from each item
- Remove empty lines
- Preserves duplicates (order matters for content like steps)

```ruby
project.highlights_list = "Step 1\nStep 2\nStep 1"
project.highlights  # => ["Step 1", "Step 2", "Step 1"]
```

### API/Agent Access

The controller permits both virtual attributes (for HTML forms) and direct arrays (for API/agent access):

```ruby
# HTML form submission
params = { project: { tech_stack_list: "Ruby, Rails" } }

# API/Agent submission
params = { project: { tech_stack: ["Ruby", "Rails"] } }
```

Both work. Agents don't need to serialize arrays to strings.

### Limitations

- `:list` items cannot contain commas (use `:lines` for comma-containing text)
- No auto-detection from JSON columns (must explicitly declare `as: :list` or `as: :lines`)
- No built-in validation (use standard Rails validators if needed)

### Adding Validation

Use standard Rails validators:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :tech_stack, as: :list

  validate :tech_stack_limit

  private

  def tech_stack_limit
    if tech_stack.length > 20
      errors.add(:tech_stack, "has too many items (maximum is 20)")
    end
  end
end
```

Or use a length validator with a guard:

```ruby
validates :tech_stack, length: { maximum: 20 }, if: -> { tech_stack.is_a?(Array) }
```

### Server Restart Required

When you add new array field declarations to a model, you must restart your Rails server. The virtual attributes are defined at class load time via `define_method`, so changes aren't picked up until the class is reloaded.

---

## Entity Registration

### Using `register_entity`

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  # Symbol registration (preferred)
  config.register_entity :project
  config.register_entity :testimonial
  config.register_entity :team_member

  # String registration also works
  config.register_entity "Portfolio"

  # Custom sidebar label
  config.register_entity :case_study, label: "Client Work"
end
```

Registration accepts:
- **Symbol**: `:project` → looks up `Project` class
- **String**: `"Project"` → looks up `Project` class
- **Class**: `Project` → uses class directly (works but symbol/string preferred)

### Development reloading

Entity configs are resolved fresh on each request. When you edit a model's `railspress_fields` declaration:

1. Rails reloads the model class
2. The next request gets the fresh field configuration
3. Forms automatically render with updated fields

No special hooks or wrappers needed.

### Check if registered

```ruby
Railspress.entity_registered?("projects")  # => true
Railspress.entity_for("projects")          # => EntityConfig instance
```

---

## Custom Labels

### Sidebar and page headers

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_label "Client Work"
  # Sidebar shows "Client Work"
  # Page titles use "Client Work" (plural) and "Client Work" singular form
end
```

If not specified, defaults to the humanized, pluralized model name (e.g., "Projects").

---

## Routes

Entity routes are automatically generated under `/railspress/admin/entities/:entity_type`:

| HTTP Method | Path | Action | Description |
|-------------|------|--------|-------------|
| GET | `/entities/projects` | index | List all projects |
| GET | `/entities/projects/new` | new | New project form |
| POST | `/entities/projects` | create | Create project |
| GET | `/entities/projects/:id` | show | View project |
| GET | `/entities/projects/:id/edit` | edit | Edit project form |
| PATCH/PUT | `/entities/projects/:id` | update | Update project |
| DELETE | `/entities/projects/:id` | destroy | Delete project |

Routes include a constraint that only allows registered entity types.

### Route helpers

Within RailsPress views and controllers, use these helpers:

```ruby
entity_index_path                    # /entities/projects
entity_new_path                      # /entities/projects/new
entity_show_path(record)             # /entities/projects/123
entity_edit_path(record)             # /entities/projects/123/edit
```

From your host app:

```ruby
railspress.admin_entity_index_path(entity_type: "projects")
railspress.admin_entity_path(entity_type: "projects", id: 123)
```

---

## Sidebar Integration

Registered entities automatically appear in the admin sidebar below the built-in sections (Posts, Categories, Tags). The sidebar uses the entity's `label` for display.

---

## EntityConfig API

The `EntityConfig` class stores configuration for each entity:

```ruby
config = Project.railspress_config

config.model_class     # => Project
config.label           # => "Client Projects"
config.singular_label  # => "Client Project"
config.route_key       # => "projects"
config.param_key       # => "project"
config.fields          # => { title: { type: :string }, ... }
```

### Field introspection

```ruby
config.fields.each do |name, field|
  puts "#{name}: #{field[:type]}"
end
# title: string
# client: string
# featured: boolean
# body: rich_text
# gallery: attachments
```

---

## Type Detection Details

When you call `railspress_fields :name` without an explicit type, detection happens lazily (on first access) in this order:

1. **ActionText**: Checks for `rich_text_#{name}` association
2. **ActiveStorage**: Checks attachment reflections for the name
3. **Database schema**: Falls back to column type from `columns_hash`
4. **Default**: Returns `:string` if no column exists

```ruby
# Detection examples
has_rich_text :content
railspress_fields :content         # Detects :rich_text

has_many_attached :photos
railspress_fields :photos          # Detects :attachments

# Column: featured boolean NOT NULL
railspress_fields :featured        # Detects :boolean
```

---

## Attachments

### Single attachment

```ruby
class Testimonial < ApplicationRecord
  include Railspress::Entity

  has_one_attached :avatar

  railspress_fields :name, :quote
  railspress_fields :avatar, as: :attachment
end
```

### Multiple attachments

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  has_many_attached :gallery

  railspress_fields :title
  railspress_fields :gallery, as: :attachments
end
```

Attachment fields support:
- Image preview thumbnails
- Individual removal checkboxes
- Direct upload (if configured in host app)
- Adding new files while keeping existing ones

---

## Focal Point Images

For images that need focal point editing (hero banners, cards, OG images), use the `focal_point_image` macro. It combines ActiveStorage attachment, focal point support, and entity field registration in one call.

### Basic Usage

```ruby
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::HasFocalPoint

  focal_point_image :cover_image
end
```

### With Variants

Define image variants for different contexts:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::HasFocalPoint

  focal_point_image :main_image do |attachable|
    attachable.variant :hero, resize_to_fill: [2100, 900, { crop: :centre }]
    attachable.variant :card, resize_to_fill: [800, 500, { crop: :centre }]
    attachable.variant :thumb, resize_to_fill: [400, 250, { crop: :centre }]
    attachable.variant :og, resize_to_fill: [1200, 630, { crop: :centre }]
  end

  # No need to declare main_image in railspress_fields - auto-registered
  railspress_fields :title, :client, :featured
end
```

### What focal_point_image Does

One call handles three things:

1. **`has_one_attached`** - Declares the ActiveStorage attachment with optional variants
2. **`has_focal_point`** - Adds focal point editing support
3. **`railspress_fields`** - Registers the field in the entity system (auto)

### Using in Views

```erb
<%# Apply focal point to hero image %>
<%= image_tag url_for(@project.main_image.variant(:hero)),
      style: @project.focal_point_css(:main_image),
      class: "object-cover w-full h-full" %>
```

See [Image Focal Point System](image-focal-point-system.md) for full documentation on focal points, context overrides, and the admin UI.

---

## Full Example

```ruby
# app/models/team_member.rb
class TeamMember < ApplicationRecord
  include Railspress::Entity

  has_one_attached :headshot
  has_rich_text :bio

  railspress_fields :name, :role, :email
  railspress_fields :bio
  railspress_fields :headshot, as: :attachment
  railspress_fields :featured, :display_order

  railspress_label "Team"

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :featured, -> { where(featured: true) }
  scope :ordered, -> { order(display_order: :asc, name: :asc) }
end
```

```ruby
# db/migrate/xxx_create_team_members.rb
class CreateTeamMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :team_members do |t|
      t.string :name, null: false
      t.string :role
      t.string :email
      t.boolean :featured, default: false
      t.integer :display_order, default: 0
      t.timestamps
    end
  end
end
```

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.register_entity :team_member
end
```

Admin available at: `/railspress/admin/entities/team_members`

---

## Pagination and Scopes

The Entity concern includes built-in pagination and common scopes.

### Pagination

Entities support simple pagination with the `page` method:

```ruby
# In your controller
@projects = Project.ordered.page(params[:page])

# Get paginated results with 20 per page (default)
Project.page(1)   # First 20 records
Project.page(2)   # Records 21-40

# Check pagination info
Project.per_page_count  # => 20 (default)
```

Override the default page size in your model:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  PER_PAGE = 50  # Override default of 20

  railspress_fields :title, :client
end
```

### Built-in Scopes

Every Entity includes these scopes:

| Scope | Description |
|-------|-------------|
| `ordered` | By `created_at` descending |
| `recent` | First 10 records, ordered |
| `page(n)` | Pagination helper (uses `PER_PAGE`) |

```ruby
# Examples
Project.ordered                    # All projects, newest first
Project.recent                     # Last 10 projects
Project.ordered.page(2)            # Second page of projects
Project.where(featured: true).recent  # Last 10 featured projects
```

### Custom Scopes

Add your own scopes as usual:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :title, :client, :featured, :published_at

  scope :published, -> { where.not(published_at: nil) }
  scope :featured, -> { where(featured: true) }
  scope :by_client, ->(client) { where(client: client) }

  # Override ordered scope if needed
  scope :ordered, -> { order(published_at: :desc, title: :asc) }
end
```

---

## Adding Tags to Entities

Make any entity taggable by including the `Railspress::Taggable` concern:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::Taggable

  railspress_fields :title, :description
end
```

### What Taggable Provides

| Method | Description |
|--------|-------------|
| `tag_list` | Returns tags as comma-separated string |
| `tag_list=` | Sets tags from comma-separated string |
| `tags` | Returns associated `Railspress::Tag` records |
| `taggings` | Returns the join records |

### Database Requirement

The taggings migration is included with RailsPress. Ensure you've run:

```bash
rails railspress:install:migrations
rails db:migrate
```

This creates the `railspress_taggings` polymorphic join table.

### Form Integration

Add a tag field to your entity form:

```erb
<%= rp_string_field f, :tag_list, label: "Tags", hint: "Comma-separated" %>
```

Or if you're building a custom form:

```erb
<%= f.text_field :tag_list, placeholder: "ruby, rails, api" %>
```

### Querying by Tags

```ruby
# Find entities with a specific tag
tag = Railspress::Tag.find_by(slug: "ruby")
tag.taggings.where(taggable_type: "Project").map(&:taggable)

# Or add a scope to your model
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::Taggable

  scope :tagged_with, ->(tag_name) {
    joins(:tags).where(railspress_tags: { name: tag_name.downcase })
  }
end

Project.tagged_with("ruby")
```

### Note on Shared Tags

Tags are shared across all taggable models. A tag "ruby" used on a Post and a Project points to the same `Railspress::Tag` record. This enables cross-model tag pages and unified tag management.

---

## Custom Index Columns

By default, entity index pages display columns based on `Railspress.default_index_columns` (defaults to `:id`, `:title`, `:name`, `:created_at`). Only columns that the model responds to are shown.

### Overriding with a Constant

Define `RAILSPRESS_INDEX_COLUMNS` in your model:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  RAILSPRESS_INDEX_COLUMNS = [:title, :client, :status, :created_at]

  railspress_fields :title, :client, :description, :status, :featured
end
```

### Overriding with a Method

For dynamic logic, override the `railspress_index_columns` class method:

```ruby
class Project < ApplicationRecord
  include Railspress::Entity

  def self.railspress_index_columns
    columns = [:title, :client, :created_at]
    columns << :budget if Current.user&.admin?
    columns
  end
end
```

### Global Default

Configure the default columns for all entities in your initializer:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.default_index_columns = [:title, :name, :updated_at]
end
```

### Column Type Rendering

| Type | Index Display |
|------|---------------|
| `:string` | Truncated text |
| `:text` | Truncated text |
| `:boolean` | Yes/No badge |
| `:integer` | Raw value |
| `:datetime` | Formatted date |
| `:date` | Formatted date |
| `:attachment` | Attached/None badge |
| `:attachments` | "N images" badge |

---

## Differences from Posts

| Feature | Posts | Entities |
|---------|-------|----------|
| Model location | Engine (`Railspress::Post`) | Host app |
| Fields | Fixed schema | User-defined via DSL |
| Categories/Tags | Built-in associations | Not included (add your own) |
| Slugs | Auto-generated | Not included (add your own) |
| Status/Publishing | Draft/Published workflow | Not included |
| SEO fields | Meta title/description | Not included |

Entities are intentionally minimal. Add your own validations, scopes, and associations as needed.

---

## Troubleshooting

### Entity not appearing in sidebar

Ensure the entity is registered in your initializer:

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.register_entity :my_model
end
```

### "Entity not found" error

Check that:
1. The model includes `Railspress::Entity`
2. The entity is registered in an initializer
3. The URL uses the correct route key (pluralized, underscored model name)

### Changes to model not reflected in form

Entity configs are resolved fresh on each request in development. If changes aren't showing:
1. Ensure you saved the model file
2. Try a full page refresh (not just Turbo navigation)
3. Check the Rails server logs for any load errors

### Fields not detected correctly

Use explicit type:

```ruby
railspress_fields :my_field, as: :rich_text
```

### Attachments not saving

Ensure ActiveStorage is set up in your host app and the model has the attachment declared:

```ruby
has_many_attached :photos
railspress_fields :photos, as: :attachments
```

### Array field methods not found (`tech_stack_list=` undefined)

After adding new `:list` or `:lines` field declarations, you must restart your Rails server:

```ruby
# You added this...
railspress_fields :tech_stack, as: :list
```

The virtual attributes (`tech_stack_list`, `tech_stack_list=`) are defined via `define_method` when the class loads. In development, Rails caches classes after the first request, so new method definitions require a server restart to take effect.

**Fix**: Restart your Rails server.
