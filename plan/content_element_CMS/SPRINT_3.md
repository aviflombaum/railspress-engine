# Sprint 3: Admin Views (Content Groups & Elements)

## Goal

Build all admin views for content groups, content elements, and version history display. Views must use the existing RailsPress admin styling system (vanilla CSS with `rp-` prefix, AdminHelper methods).

## Design Reference

Follow the exact patterns from existing RailsPress views:
- **Categories index** (`admin/categories/index.html.erb`): `rp_page_header`, `rp-card`, `rp-table`, `rp_table_action_icons`, `rp_empty_state`
- **Posts views**: Complex form pattern with two-column layout and sidebar
- **AdminHelper methods**: `rp_render_field`, `rp_form_errors`, `rp_form_actions`, `rp_page_header`, `rp_status_badge`, `rp_badge`, `rp_card`, `rp_sidebar_section`

## Tasks

### 3.1 Content Groups - Index View

**File**: `app/views/railspress/admin/content_groups/index.html.erb`

Table with columns: Name, Description (truncated), Elements Count, Actions (edit, delete).
Uses `rp_page_header`, `rp-table`, `rp_table_action_icons`, `rp_empty_state`.

### 3.2 Content Groups - Show View

**File**: `app/views/railspress/admin/content_groups/show.html.erb`

Display group details and list its content elements in a table.
Header with Edit/Back buttons. Element count badge.
Elements table with: Name, Type badge, Content preview, Position, Actions.

### 3.3 Content Groups - New/Edit Views + Form Partial

**Files**:
- `app/views/railspress/admin/content_groups/new.html.erb`
- `app/views/railspress/admin/content_groups/edit.html.erb`
- `app/views/railspress/admin/content_groups/_form.html.erb`

Simple form pattern (like categories): name field, description textarea.
Uses `rp_string_field`, `rp_text_field`, `rp_form_errors`, `rp_form_actions`.

### 3.4 Content Elements - Index View

**File**: `app/views/railspress/admin/content_elements/index.html.erb`

Table with columns: Name, Group (link), Type badge, Content preview, Updated, Actions.
Group filter dropdown at the top.
Uses `rp_page_header`, `rp-table`, `rp_status_badge`.

### 3.5 Content Elements - Show View

**File**: `app/views/railspress/admin/content_elements/show.html.erb`

Two-column layout:
- **Main content**: Content preview, version history timeline
- **Sidebar**: Element details (group, type, position, created/updated), API usage code snippet

### 3.6 Content Elements - New/Edit Views + Form Partial

**Files**:
- `app/views/railspress/admin/content_elements/new.html.erb`
- `app/views/railspress/admin/content_elements/edit.html.erb`
- `app/views/railspress/admin/content_elements/_form.html.erb`

Complex form with:
- Name (string, primary)
- Content Group (select dropdown)
- Content Type (select: text/image)
- Text Content (textarea, shown when type=text)
- Position (integer)

Uses `rp_string_field`, `rp_select_field`, `rp_text_field`, `rp_integer_field`.

### 3.7 Content Element Versions - Show View

**File**: `app/views/railspress/admin/content_element_versions/show.html.erb`

Version detail view with:
- Version number and created date
- Text content preview
- Back to element link
- Element info sidebar

### 3.8 Update Admin Navigation

Add "Content" section to the admin sidebar/navigation with links to:
- Content Groups
- Content Elements

## Acceptance Criteria

- [ ] Content Groups: index, show, new, edit all render correctly
- [ ] Content Elements: index, show, new, edit all render correctly
- [ ] Version show page renders correctly
- [ ] All views use `rp-` CSS classes (no Tailwind)
- [ ] All views use AdminHelper methods for consistency
- [ ] Empty states shown when no records
- [ ] Form validation errors display properly
- [ ] Navigation includes Content section

## Dependencies

- Sprint 1 (models)
- Sprint 2 (controllers and routes)
