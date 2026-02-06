# Sprint 1: Core Models, Migrations & SoftDeletable Concern

## Goal

Create the database tables and ActiveRecord models for ContentGroup, ContentElement, and ContentElementVersion, plus the SoftDeletable concern. This is the data foundation for the entire CMS feature.

## Tasks

### 1.1 Create SoftDeletable Concern

**File**: `app/models/concerns/railspress/soft_deletable.rb`

Extracted from `innovent-rails/app/models/concerns/soft_deletable.rb`. Provides:
- `soft_delete` - sets `deleted_at` timestamp
- `restore` - clears `deleted_at`
- `deleted?` - checks if soft-deleted
- `active` scope - excludes soft-deleted records

```ruby
module Railspress
  module SoftDeletable
    extend ActiveSupport::Concern

    included do
      scope :active, -> { where(deleted_at: nil) }
    end

    def deleted?
      deleted_at.present?
    end

    def soft_delete
      update(deleted_at: Time.current)
    end

    def restore
      update(deleted_at: nil)
    end
  end
end
```

### 1.2 Create ContentGroup Migration

**File**: `db/migrate/YYYYMMDD000011_create_railspress_content_groups.rb`

```ruby
class CreateRailspressContentGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_content_groups do |t|
      t.string :name, null: false
      t.text :description
      t.bigint :author_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :railspress_content_groups, :name, unique: true
    add_index :railspress_content_groups, :deleted_at
    add_index :railspress_content_groups, :author_id
  end
end
```

### 1.3 Create ContentElement Migration

**File**: `db/migrate/YYYYMMDD000012_create_railspress_content_elements.rb`

```ruby
class CreateRailspressContentElements < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_content_elements do |t|
      t.string :name, null: false
      t.integer :content_type, default: 0, null: false
      t.text :text_content
      t.references :content_group, null: false, foreign_key: { to_table: :railspress_content_groups }
      t.bigint :author_id
      t.integer :position
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :railspress_content_elements, :deleted_at
    add_index :railspress_content_elements, :author_id
    add_index :railspress_content_elements, :content_type
  end
end
```

### 1.4 Create ContentElementVersion Migration

**File**: `db/migrate/YYYYMMDD000013_create_railspress_content_element_versions.rb`

```ruby
class CreateRailspressContentElementVersions < ActiveRecord::Migration[8.0]
  def change
    create_table :railspress_content_element_versions do |t|
      t.references :content_element, null: false, foreign_key: { to_table: :railspress_content_elements }
      t.bigint :author_id
      t.text :text_content
      t.integer :version_number, null: false

      t.timestamps
    end

    add_index :railspress_content_element_versions,
              [:content_element_id, :version_number],
              unique: true,
              name: "idx_content_element_versions_unique"
    add_index :railspress_content_element_versions, :author_id
  end
end
```

### 1.5 Create ContentGroup Model

**File**: `app/models/railspress/content_group.rb`

Based on `innovent-rails/app/models/content_group.rb`:
- `has_many :content_elements`
- `include SoftDeletable`
- Validates name presence and uniqueness
- `element_count` method
- Cascading soft delete to child elements

### 1.6 Create ContentElement Model

**File**: `app/models/railspress/content_element.rb`

Based on `innovent-rails/app/models/content_element.rb`:
- `belongs_to :content_group`
- `has_many :content_element_versions`
- `has_one_attached :image` (for future image support)
- `enum :content_type, { text: 0, image: 1 }`
- `include SoftDeletable`
- Auto-versioning via `after_save :create_version`
- `value` method returns text_content or image URL
- `restore_to_version(version_number)` method

### 1.7 Create ContentElementVersion Model

**File**: `app/models/railspress/content_element_version.rb`

Based on `innovent-rails/app/models/content_element_version.rb`:
- `belongs_to :content_element`
- `has_one_attached :image_version` (future)
- `changes_from_previous` method
- Scopes: `ordered`, `recent`

### 1.8 Run Migrations in Dummy App

```bash
cd spec/dummy && bin/rails db:migrate && cd ../..
```

## Acceptance Criteria

- [ ] All three migrations run successfully in the dummy app
- [ ] `Railspress::ContentGroup.create!(name: "Test")` works
- [ ] `Railspress::ContentElement.create!(name: "Test", content_group: group, content_type: :text, text_content: "Hello")` works
- [ ] Saving a content element auto-creates a version
- [ ] `soft_delete` and `restore` work on groups and elements
- [ ] `active` scope filters out soft-deleted records

## Dependencies

None - this is the foundation sprint.
