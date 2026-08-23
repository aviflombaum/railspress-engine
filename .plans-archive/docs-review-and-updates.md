---
title: "Review and Update Documentation for Recent Features"
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Feature, configuration, entity, helper, theming, changelog, and cross-reference documentation is present and contract-tested."
---

# docs: Review and Update Documentation for Recent Features

## Overview

Review documentation against features added in the last 20 commits and create comprehensive updates to ensure all functionality is properly documented.

## Problem Statement

After analyzing the last 20 commits against existing documentation, **5 features are undocumented** and **3 repository hygiene items are missing**. Users cannot discover new functionality like markdown mode, custom entity columns, or the Taggable concern without reading source code.

## Research Findings

### Features Added in Last 20 Commits

| Commit | Feature | Documented? |
|--------|---------|-------------|
| `6b3aa9e` | Focal point system | Yes (image-focal-point-system.md) |
| `46886f7` | Custom columns on entity index | **No** |
| `23201d8` | Markdown mode for content editing | **No** |
| `003bb0d` | `blog_path` configuration | Yes (CONFIGURING.md) |
| `79c7c69` | Polymorphic tagging (Taggable concern) | **No** |
| `7c75567` | Entity system | Yes (ENTITIES.md) |
| `45adb2a` | Collapsible sidebar | **No** |
| `06d4d8d` | Import/Export | Yes (IMPORT_EXPORT.md) |
| `efbc8ca` | Dropzone for file imports | Partially |

### Current Documentation Structure

```
docs/
├── README.md              # Index and models reference
├── ENTITIES.md            # Entity system (645 lines)
├── BLOGGING.md            # Frontend blog guide (780 lines)
├── CONFIGURING.md         # Configuration options
├── THEMING.md             # CSS variables
├── IMPORT_EXPORT.md       # Bulk operations
├── ADMIN_HELPERS.md       # Helper method reference
├── TROUBLESHOOTING.md     # Common issues
├── UPGRADING.md           # Migration guide
└── image-focal-point-system.md  # Focal point feature
```

### Gaps Identified

**Critical (Blocking User Success)**:
1. `enable_focal_points` config missing from CONFIGURING.md
2. Markdown mode completely undocumented
3. Custom entity index columns undocumented

**Important (Feature Discoverability)**:
4. No CHANGELOG.md
5. Taggable concern undocumented
6. Collapsible sidebar undocumented

**Nice-to-Have (Repository Hygiene)**:
7. No GitHub issue templates
8. No PR template
9. Configuration class audit incomplete

---

## Acceptance Criteria

### Functional Requirements

- [ ] All 5 undocumented features have documentation
- [ ] CONFIGURING.md includes `enable_focal_points` toggle
- [ ] ENTITIES.md includes custom columns section
- [ ] ENTITIES.md includes Taggable concern section
- [ ] README.md feature list updated with markdown mode
- [ ] CHANGELOG.md exists covering last 20 commits

### Non-Functional Requirements

- [ ] Documentation follows existing style (markdown, tables, code blocks)
- [ ] All code examples are copy-pasteable
- [ ] Cross-references between docs are accurate

### Quality Gates

- [ ] Every config option in `Railspress::Configuration` is documented
- [ ] Every public method in Entity concern is documented

---

## Implementation Phases

### Phase 1: Critical Documentation Gaps

**Task 1.1: Add `enable_focal_points` to CONFIGURING.md**

Location: `docs/CONFIGURING.md:39-63` (after `enable_post_images`)

```markdown
#### `enable_focal_points`

Enables focal point selection for header images. When enabled, editors can set the focal point (important area) of images to control cropping across different aspect ratios.

\`\`\`ruby
Railspress.configure do |config|
  config.enable_post_images    # Required first
  config.enable_focal_points   # Then enable focal points
end
\`\`\`

**Default:** Disabled

**Requirements:** Must also enable `enable_post_images`. Requires running migrations for `railspress_focal_points` table.

See [Image Focal Point System](image-focal-point-system.md) for full documentation.
```

**Task 1.2: Document markdown mode**

Create section in `docs/BLOGGING.md` OR create new `docs/MARKDOWN_MODE.md`:

Content to document:
- Toggle button in post form (Lexxy editor)
- How to switch between rich text and markdown
- Markdown syntax supported
- Conversion behavior (HTML to Markdown and back)
- Update README.md feature list to mention "Markdown editing mode"

**Task 1.3: Document custom entity index columns**

Location: `docs/ENTITIES.md` (new section after "Pagination and Scopes")

```markdown
## Custom Index Columns

By default, entity index pages show the first 3-4 fields declared in `railspress_fields`. Override this with `railspress_index_columns`:

\`\`\`ruby
class Project < ApplicationRecord
  include Railspress::Entity

  railspress_fields :title, :client, :description, :featured, :created_at
  railspress_fields :body

  # Show specific columns in index table
  railspress_index_columns :title, :client, :featured, :created_at
end
\`\`\`

### Supported Column Types

| Type | Rendering |
|------|-----------|
| `:string` | Truncated text (50 chars) |
| `:boolean` | Yes/No badge |
| `:datetime` | Formatted date |
| `:attachment` | Attached/None badge |

### Global Default

Configure default columns in your initializer:

\`\`\`ruby
Railspress.configure do |config|
  config.default_index_columns = [:title, :updated_at]
end
\`\`\`
```

---

### Phase 2: Feature Discoverability

**Task 2.1: Create CHANGELOG.md**

Location: `CHANGELOG.md` (root directory)

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)

Content from last 20 commits:

```markdown
# Changelog

All notable changes to RailsPress will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Focal point system for header images with per-context overrides
- Markdown editing mode toggle in post form
- Custom index columns for entities (`railspress_index_columns`)
- Collapsible sidebar in admin interface
- Polymorphic tagging with `Railspress::Taggable` concern
- `blog_path` configuration for View button links
- Dropzone for drag-and-drop file imports
- Reading time auto-calculation for posts
- Refactored tables with cleaner styling

### Changed
- Tags now use polymorphic `taggings` table (previously `post_tags`)
- CSS split into component files for better maintainability
- License updated to O'Saasy License

### Fixed
- Crash when header image validation fails
- Import type hidden field nesting under import params
```

**Task 2.2: Document Taggable concern**

Location: `docs/ENTITIES.md` (new section "Adding Tags to Entities")

```markdown
## Adding Tags to Entities

Make any entity taggable by including the `Railspress::Taggable` concern:

\`\`\`ruby
class Project < ApplicationRecord
  include Railspress::Entity
  include Railspress::Taggable

  railspress_fields :title, :description
end
\`\`\`

### What Taggable Provides

| Method | Description |
|--------|-------------|
| `tag_list` | Returns tags as comma-separated string |
| `tag_list=` | Sets tags from comma-separated string |
| `tags` | Returns associated Tag records |

### Database Requirement

The taggings migration is included with RailsPress. Ensure you've run:

\`\`\`bash
rails railspress:install:migrations
rails db:migrate
\`\`\`

### Form Integration

Add a tag field to your entity form:

\`\`\`erb
<%= rp_string_field f, :tag_list, label: "Tags", hint: "Comma-separated" %>
\`\`\`

### Note

Tags are shared across all taggable models. A tag "ruby" used on a Post and a Project points to the same `Railspress::Tag` record.
```

**Task 2.3: Document collapsible sidebar**

Location: `docs/THEMING.md` (new section) or `docs/ADMIN_HELPERS.md`

```markdown
## Collapsible Sidebar

The admin sidebar can be collapsed by clicking the toggle button. State persists across sessions via localStorage.

### CSS Classes

\`\`\`css
/* Collapsed state */
.rp-sidebar--collapsed { }

/* Toggle button */
.rp-sidebar__toggle { }
```

---

### Phase 3: Repository Hygiene

**Task 3.1: Create GitHub issue templates**

Location: `.github/ISSUE_TEMPLATE/bug_report.yml`

```yaml
name: Bug Report
description: Report a bug in RailsPress
labels: ["bug"]
body:
  - type: input
    attributes:
      label: RailsPress version
      placeholder: "1.0.0"
    validations:
      required: true
  - type: input
    attributes:
      label: Rails version
      placeholder: "8.0.0"
    validations:
      required: true
  - type: textarea
    attributes:
      label: Steps to reproduce
    validations:
      required: true
  - type: textarea
    attributes:
      label: Expected behavior
    validations:
      required: true
  - type: textarea
    attributes:
      label: Actual behavior
    validations:
      required: true
  - type: textarea
    attributes:
      label: Error logs
      render: shell
```

Location: `.github/ISSUE_TEMPLATE/feature_request.yml`

```yaml
name: Feature Request
description: Suggest a new feature
labels: ["enhancement"]
body:
  - type: textarea
    attributes:
      label: Problem to solve
      placeholder: What problem does this feature solve?
    validations:
      required: true
  - type: textarea
    attributes:
      label: Proposed solution
    validations:
      required: true
  - type: textarea
    attributes:
      label: Alternatives considered
```

**Task 3.2: Create PR template**

Location: `.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## Summary

<!-- Brief description of changes -->

## Checklist

- [ ] Tests added/updated
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated
- [ ] RuboCop passing (`bin/rubocop`)
```

---

### Phase 4: Polish

**Task 4.1: Audit configuration class**

Review `lib/railspress.rb` Configuration class and ensure all options are in CONFIGURING.md:

- [ ] `enable_authors`
- [ ] `enable_post_images`
- [ ] `enable_focal_points` (missing, add in Phase 1)
- [ ] `author_class_name`
- [ ] `current_author_method`
- [ ] `author_scope`
- [ ] `author_display_method`
- [ ] `current_author_proc`
- [ ] `words_per_minute`
- [ ] `blog_path`
- [ ] `image_contexts` (in focal point doc)
- [ ] `default_index_columns` (add in Phase 1)

**Task 4.2: Update README feature list**

Location: `README.md:7-14`

Add:
```markdown
- Markdown editing mode (toggle between rich text and markdown)
- Image focal points for smart cropping
```

**Task 4.3: Add troubleshooting entries**

Location: `docs/TROUBLESHOOTING.md`

Add entries for:
- Focal point not saving (nested attributes permit issue)
- Stimulus controllers not loading (missing import)
- Entity index columns not showing custom columns

---

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `docs/CONFIGURING.md` | Edit | Add `enable_focal_points` section |
| `docs/ENTITIES.md` | Edit | Add custom columns + Taggable sections |
| `docs/BLOGGING.md` | Edit | Add markdown mode section |
| `docs/THEMING.md` | Edit | Add collapsible sidebar section |
| `docs/TROUBLESHOOTING.md` | Edit | Add new troubleshooting entries |
| `README.md` | Edit | Update feature list |
| `CHANGELOG.md` | Create | New file with last 20 commits |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | Create | Bug report template |
| `.github/ISSUE_TEMPLATE/feature_request.yml` | Create | Feature request template |
| `.github/PULL_REQUEST_TEMPLATE.md` | Create | PR template |

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Documentation drift | High | Medium | Add docs checklist to PR template |
| Incomplete coverage | Medium | Low | Audit all config options |
| Breaking links | Low | Low | Test cross-references |

---

## References

### Internal References
- Configuration class: `lib/railspress.rb:1-100`
- Entity concern: `lib/railspress/entity.rb:1-250`
- Taggable concern: `app/models/concerns/railspress/taggable.rb`
- Focal point concern: `app/models/concerns/railspress/has_focal_point.rb`
- Markdown mode JS: `app/assets/javascripts/railspress/markdown_mode.js`

### Commits Analyzed
```
6b3aa9e "focal point"
07b46a4 "refactored tables"
46886f7 "custom columns on index for entities"
23201d8 "Markdown mode"
79c7c69 "A lot" (Taggable concern)
45adb2a "collapsible sidebar"
06d4d8d "Post import and exports"
003bb0d feat(config): add blog_path configuration
```

### External References
- [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
- [GitHub Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
