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

### Form layout

Fields are automatically organized into a two-column layout:

- **Main column**: String, text, and rich text fields
- **Sidebar**: Boolean, numeric, and date fields in an "Options" section
- **Sidebar**: Each attachment field gets its own section with preview and removal

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
