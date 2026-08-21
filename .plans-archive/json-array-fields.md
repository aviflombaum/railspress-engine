---
title: "JSON Array Fields for RailsPress Entities"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "List/lines entity fields, serialization, forms, rendering, round trips, documentation, and specs are present."
---

# JSON Array Fields for RailsPress Entities

Add support for JSON array fields (`:list` and `:lines` types) in the Entity system so entities can store arrays of strings editable in the CMS admin.

## Problem Statement

The avi.nyc Project entity needs fields like:
- `tech_stack`: `["Ruby", "Rails", "PostgreSQL"]` - short technology names
- `highlights`: `["10k users", "95% retention", "Featured in Ruby Weekly"]` - achievement sentences

Current RailsPress Entity system only supports scalar types and attachments. JSON array fields require:
1. A way to declare them in the entity config
2. Form inputs for editing (textarea-based)
3. Parsing logic (string input → array storage)
4. Display rendering in admin views

## Design Principles

**Convention over Configuration**: One declaration should be enough. The system auto-wires everything.

```ruby
# This is ALL the user writes:
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :tech_stack, as: :list
  railspress_fields :highlights, as: :lines
end
```

No extra concerns. No extra macros. No boilerplate nil guards.

## Two Field Types

| Type | Input Format | Best For | Deduplicates? |
|------|--------------|----------|---------------|
| `:list` | Comma-separated | Short strings, tags | Yes |
| `:lines` | One per line | Sentences, paragraphs | No (preserves order) |

Both store as JSON arrays in the database.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           User Input                                 │
├─────────────────────────────────────────────────────────────────────┤
│  :list field                    │  :lines field                     │
│  ┌───────────────────────────┐  │  ┌───────────────────────────┐   │
│  │ Ruby, Rails, PostgreSQL   │  │  │ Built API in 2 weeks      │   │
│  └───────────────────────────┘  │  │ Reduced load time by 50%  │   │
│                                  │  │ Featured in Ruby Weekly   │   │
│                                  │  └───────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                   Auto-Generated Virtual Attribute                   │
│                                                                      │
│  def tech_stack_list=(value)       def highlights_list=(value)      │
│    self.tech_stack =                 self.highlights =              │
│      value.split(",")                  value.split("\n")            │
│           .map(&:strip)                     .map(&:strip)           │
│           .reject(&:blank?)                 .reject(&:blank?)       │
│           .uniq                                                      │
│  end                               end                               │
├─────────────────────────────────────────────────────────────────────┤
│                        Database (JSONB)                              │
│                                                                      │
│  tech_stack: ["Ruby", "Rails", "PostgreSQL"]                        │
│  highlights: ["Built API in 2 weeks", "Reduced load time by 50%"]   │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Decisions

### 1. Auto-Wire Virtual Attributes
**Decision**: When `railspress_fields :tech_stack, as: :list` is called, auto-generate:
- `tech_stack` returns `[]` instead of `nil`
- `tech_stack_list` getter (array → string)
- `tech_stack_list=` setter (string → array)

No separate concern. No extra declaration.

### 2. Empty Array Persistence
**Decision**: Save as `[]` (empty array), never `nil`
- Migration default: `default: []`
- Model override: `def tech_stack; super || []; end` (auto-generated)

### 3. Whitespace & Empty Item Handling
**Decision**: Strip whitespace, filter blanks, auto-dedupe for `:list`
```ruby
# Input: "Ruby  ,, Rails ,  JavaScript  "
# Output: ["Ruby", "Rails", "JavaScript"]
```
For `:lines`, preserve order but still strip/filter blanks.

### 4. Comma Handling
**Decision**: `:list` fields cannot contain commas in values. Use `:lines` for comma-containing text.

### 5. No Auto-Detection from JSON Columns
**Decision**: Require explicit `as: :list` or `as: :lines`. Don't guess from json/jsonb column type.

### 6. Strong Params: Permit Both
**Decision**: Permit both virtual attribute AND direct array for agent/API parity:
```ruby
# Human form
params = { project: { tech_stack_list: "Ruby, Rails" } }

# Agent/API
params = { project: { tech_stack: ["Ruby", "Rails"] } }
```

### 7. No Custom Validator (YAGNI)
**Decision**: Don't create ArrayLengthValidator for MVP. Use standard Rails if needed:
```ruby
validates :tech_stack, length: { maximum: 20 }, if: -> { tech_stack.is_a?(Array) }
```

## Implementation Plan

### Phase 1: Core Infrastructure

#### 1.1 Update EntityConfig to Auto-Wire Virtual Attributes
**File**: `lib/railspress/entity.rb`

```ruby
class EntityConfig
  def add_field(name, options = {})
    type = options[:as]
    @field_definitions[name.to_sym] = {
      type: type,
      options: options.except(:as),
      needs_detection: type.nil?
    }

    # Auto-wire virtual attributes for array types
    if type.in?([:list, :lines])
      define_array_accessors(name, type)
    end
  end

  private

  def define_array_accessors(name, type)
    separator = type == :list ? ", " : "\n"
    delimiter = type == :list ? "," : /\r?\n/
    dedupe = type == :list

    model_class.class_eval do
      # Nil guard - always return array
      define_method(name) do
        super() || []
      end

      # Virtual getter: array → string
      define_method("#{name}_list") do
        send(name).join(separator)
      end

      # Virtual setter: string → array
      define_method("#{name}_list=") do |value|
        parsed = value.to_s.split(delimiter).map(&:strip).reject(&:blank?)
        parsed = parsed.uniq if dedupe
        send("#{name}=", parsed)
      end
    end
  end
end
```

#### 1.2 Add AdminHelper Field Renderers
**File**: `app/helpers/railspress/admin_helper.rb`

```ruby
# Add to rp_render_field dispatcher:
when :list
  rp_list_field(form, name, **options)
when :lines
  rp_lines_field(form, name, **options)

# New helper methods:
def rp_list_field(form, name, label: nil, hint: nil, placeholder: nil, **options)
  virtual_name = "#{name}_list"

  content_tag(:div, class: "rp-form-group") do
    safe_join([
      form.label(virtual_name, label || name.to_s.humanize, class: "rp-label"),
      form.text_field(virtual_name,
        class: "rp-input",
        placeholder: placeholder || "Item 1, Item 2, Item 3",
        **options
      ),
      rp_hint(hint || "Separate items with commas")
    ])
  end
end

def rp_lines_field(form, name, rows: 5, label: nil, hint: nil, placeholder: nil, **options)
  virtual_name = "#{name}_list"

  content_tag(:div, class: "rp-form-group") do
    safe_join([
      form.label(virtual_name, label || name.to_s.humanize, class: "rp-label"),
      form.text_area(virtual_name,
        rows: rows,
        class: "rp-input",
        placeholder: placeholder || "One item per line",
        **options
      ),
      rp_hint(hint || "Enter one item per line")
    ])
  end
end
```

#### 1.3 Update Form Layout Categories
**File**: `app/views/railspress/admin/entities/_form.html.erb`

```erb
<%
  main_types = [:string, :text, :rich_text, :lines]
  sidebar_types = [:boolean, :integer, :decimal, :datetime, :date, :list]
  attachment_types = [:attachment, :attachments]
%>
```

### Phase 2: Display Rendering

#### 2.1 Show View Display
**File**: `app/views/railspress/admin/entities/show.html.erb`

```erb
<% when :list %>
  <% if value.is_a?(Array) && value.any? %>
    <span class="rp-list-inline">
      <%= value.join(", ") %>
    </span>
  <% else %>
    <span class="rp-text-muted">-</span>
  <% end %>

<% when :lines %>
  <% if value.is_a?(Array) && value.any? %>
    <ul class="rp-list-block">
      <% value.each do |item| %>
        <li><%= item %></li>
      <% end %>
    </ul>
  <% else %>
    <span class="rp-text-muted">-</span>
  <% end %>
```

#### 2.2 Index View Display
**File**: `app/views/railspress/admin/entities/index.html.erb`

```erb
<% when :list, :lines %>
  <% count = value.is_a?(Array) ? value.length : 0 %>
  <span class="rp-badge <%= count > 0 ? 'rp-badge--info' : '' %>">
    <%= pluralize(count, "item") %>
  </span>
```

### Phase 3: Controller Updates

#### 3.1 Update Strong Parameters
**File**: `app/controllers/railspress/admin/entities_controller.rb`

```ruby
def entity_params
  permitted = []
  entity_config.fields.each do |name, field|
    case field[:type]
    when :attachments
      permitted << { name => [] }
    when :list, :lines
      # Permit virtual attribute for HTML forms
      permitted << "#{name}_list"
      # Also permit direct array for API/agent access
      permitted << { name => [] }
    else
      permitted << name
    end
  end
  params.require(entity_config.param_key).permit(*permitted)
end
```

### Phase 4: Tests

#### 4.1 Unit Tests for Virtual Attributes
**File**: `spec/models/railspress/entity_array_fields_spec.rb`

```ruby
RSpec.describe "Entity array fields" do
  # Create a test model with array fields
  let(:model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "projects"
      include Railspress::Entity

      railspress_fields :tech_stack, as: :list
      railspress_fields :highlights, as: :lines
    end
  end

  describe ":list field" do
    it "returns empty array instead of nil" do
      project = model_class.new
      expect(project.tech_stack).to eq([])
    end

    it "parses comma-separated input" do
      project = model_class.new
      project.tech_stack_list = "Ruby, Rails, PostgreSQL"
      expect(project.tech_stack).to eq(["Ruby", "Rails", "PostgreSQL"])
    end

    it "deduplicates values" do
      project = model_class.new
      project.tech_stack_list = "Ruby, Rails, Ruby"
      expect(project.tech_stack).to eq(["Ruby", "Rails"])
    end

    it "strips whitespace and filters blanks" do
      project = model_class.new
      project.tech_stack_list = "  Ruby  ,, Rails ,  "
      expect(project.tech_stack).to eq(["Ruby", "Rails"])
    end

    it "serializes array to comma-separated string" do
      project = model_class.new(tech_stack: ["Ruby", "Rails"])
      expect(project.tech_stack_list).to eq("Ruby, Rails")
    end
  end

  describe ":lines field" do
    it "parses line-separated input" do
      project = model_class.new
      project.highlights_list = "Line 1\nLine 2\nLine 3"
      expect(project.highlights).to eq(["Line 1", "Line 2", "Line 3"])
    end

    it "preserves duplicates" do
      project = model_class.new
      project.highlights_list = "Same\nSame\nDifferent"
      expect(project.highlights).to eq(["Same", "Same", "Different"])
    end

    it "handles CRLF line endings" do
      project = model_class.new
      project.highlights_list = "Line 1\r\nLine 2"
      expect(project.highlights).to eq(["Line 1", "Line 2"])
    end
  end
end
```

## Files to Create/Modify

### Modified Files Only (No New Concerns!)

| File | Changes |
|------|---------|
| `lib/railspress/entity.rb` | Add `define_array_accessors` method, update `add_field` |
| `app/helpers/railspress/admin_helper.rb` | Add `rp_list_field`, `rp_lines_field` helpers |
| `app/views/railspress/admin/entities/_form.html.erb` | Add `:list`/`:lines` to layout categories |
| `app/views/railspress/admin/entities/show.html.erb` | Add display cases for array types |
| `app/views/railspress/admin/entities/index.html.erb` | Add badge display for array types |
| `app/controllers/railspress/admin/entities_controller.rb` | Permit both virtual and direct array params |
| `spec/models/railspress/entity_array_fields_spec.rb` | New test file |

## Example Usage

### In Host App Model

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :title, :tagline, :slug
  railspress_fields :tech_stack, as: :list
  railspress_fields :highlights, as: :lines

  railspress_label "Projects"

  validates :title, presence: true
end
```

That's it. No extra includes, no extra macros, no boilerplate.

### Migration

```ruby
class AddArrayFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :tech_stack, :jsonb, default: [], null: false
    add_column :projects, :highlights, :jsonb, default: [], null: false
  end
end
```

## Success Criteria

- [ ] `:list` fields render as text input with comma-separation
- [ ] `:lines` fields render as textarea with line-separation
- [ ] Arrays persist correctly to JSON columns
- [ ] Empty input saves as `[]` not `nil`
- [ ] Whitespace is stripped, blanks filtered
- [ ] `:list` auto-deduplicates values
- [ ] `:lines` preserves duplicates (semantic difference)
- [ ] Show view displays arrays appropriately (inline vs bullet)
- [ ] Index view shows item count badge
- [ ] Round-trip editing works (edit -> save -> edit again)
- [ ] Both `tech_stack_list` and `tech_stack: []` params work
- [ ] No custom validator created (YAGNI)

## Future Enhancements (v1.1+)

1. **Visual tag chips** - Stimulus controller for add/remove UI
2. **Drag-and-drop reordering** - For `:lines` fields
3. **Autocomplete** - For `:list` fields with suggestions
4. **Live preview** - Show parsed array count

## References

- avi.nyc Project model: `/Users/avi/Development/code/avinyc/avi.nyc/avinyc-rails/app/models/project.rb`
- Existing Entity implementation: `lib/railspress/entity.rb`
- AdminHelper patterns: `app/helpers/railspress/admin_helper.rb`
