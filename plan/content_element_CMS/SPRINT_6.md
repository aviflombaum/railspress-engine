# Sprint 6: Testing (Fixtures, Model & Request Specs)

## Goal

Add comprehensive test coverage for the content CMS feature following RailsPress testing conventions (RSpec, fixtures, transactional fixtures).

## Tasks

### 6.1 Create Fixtures

**Files**:
- `spec/fixtures/railspress/content_groups.yml`
- `spec/fixtures/railspress/content_elements.yml`
- `spec/fixtures/railspress/content_element_versions.yml`

```yaml
# content_groups.yml
headers:
  name: Headers
  description: Site header content elements
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>

footers:
  name: Footers
  description: Site footer content elements
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>

deleted_group:
  name: Deleted Group
  description: A soft-deleted group
  deleted_at: <%= Time.current %>
  created_at: <%= Time.current %>
  updated_at: <%= Time.current %>
```

### 6.2 Model Specs - ContentGroup

**File**: `spec/models/railspress/content_group_spec.rb`

Test:
- Associations (has_many content_elements)
- Validations (name presence, uniqueness)
- Scopes (active)
- Soft delete behavior
- Restore behavior
- Cascading soft delete to elements
- `element_count` method

### 6.3 Model Specs - ContentElement

**File**: `spec/models/railspress/content_element_spec.rb`

Test:
- Associations (belongs_to content_group, has_many versions)
- Validations (name presence, content_type presence, text_content for text type)
- Enum (content_type: text, image)
- Scopes (active, by_group, by_content_type)
- Auto-versioning on save
- `value` method
- `version_count` method
- `restore_to_version` method

### 6.4 Model Specs - ContentElementVersion

**File**: `spec/models/railspress/content_element_version_spec.rb`

Test:
- Associations (belongs_to content_element)
- Validations (version_number presence and uniqueness per element)
- Scopes (ordered, recent)
- `changes_from_previous` method

### 6.5 Request Specs - ContentGroups

**File**: `spec/requests/railspress/admin/content_groups_spec.rb`

Test all CRUD operations:
- GET index returns 200
- GET show returns 200
- GET new returns 200
- POST create with valid params
- POST create with invalid params
- GET edit returns 200
- PATCH update with valid params
- DELETE destroy performs soft delete

### 6.6 Request Specs - ContentElements

**File**: `spec/requests/railspress/admin/content_elements_spec.rb`

Test all CRUD operations similar to groups, plus:
- Filtering by group
- Version creation on update
- Turbo Frame responses for inline editing

## Acceptance Criteria

- [ ] All fixtures load without errors
- [ ] All model specs pass
- [ ] All request specs pass
- [ ] `bundle exec rspec` passes with no failures

## Dependencies

- Sprint 1-3 (all code complete)
