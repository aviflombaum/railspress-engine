# Content Element CMS - Feature Plan

## Overview

Extract and adapt the Content Element CMS system from Innovent Rails (`innovent-rails`) into the RailsPress mountable engine. This feature allows users to create **Content Groups** (logical containers like "Homepage", "Footer", "About Page") and **Content Elements** within them (individual pieces like "Hero H1", "Tagline", "Logo Image"). Each element is either text or image, automatically versioned on save, and soft-deletable.

Host applications can then use a chainable helper API to load content in views:
```ruby
<%= cms_value("Homepage", "Hero H1") %>
# or
<%= cms_element(group: "Homepage", name: "Hero H1") do |value| %>
  <h1><%= value %></h1>
<% end %>
```

Eventually, authenticated admins will be able to right-click content on the live site and edit it inline via Turbo Frames.

## Source Reference

The working implementation lives in the Innovent Rails app:
- **Models**: `innovent-rails/app/models/content_group.rb`, `content_element.rb`, `content_element_version.rb`
- **Concern**: `innovent-rails/app/models/concerns/soft_deletable.rb`
- **Helper**: `innovent-rails/app/helpers/cms_helper.rb`
- **Controllers**: `innovent-rails/app/controllers/admin/content_groups_controller.rb`, `content_elements_controller.rb`
- **JS**: `innovent-rails/app/javascript/controllers/cms-inline-editor_controller.js`
- **Inline CMS Plan**: `innovent-rails/.ai/inline_cms_editor_plan.md`
- **RailsPress existing plans**: `.ai/PLAN.md`, `.ai/FEATURE_LIST.md`, `.ai/CODE_REFERENCES.md`

## Adaptation Requirements

The Innovent implementation must be adapted to RailsPress engine conventions:

| Aspect | Innovent Rails | RailsPress Engine |
|--------|---------------|-------------------|
| Model namespace | `ContentGroup` | `Railspress::ContentGroup` |
| Table prefix | `content_groups` | `railspress_content_groups` |
| Controller namespace | `Admin::ContentGroupsController` | `Railspress::Admin::ContentGroupsController` |
| Styling | Tailwind CSS | Vanilla CSS with `rp-` prefix (BEM) |
| Pagination | Kaminari gem | Simple pagination (no gem dependency) |
| User tracking | `belongs_to :user` | `bigint :author_id` (configurable, like posts) |
| Helper system | Global `CMSHelper` | `Railspress::CmsHelper` engine module |
| Authentication | `require_admin_authentication` | Engine's configurable auth system |
| Routes | `/admin/content_groups` | Engine mount + `/admin/content_groups` |

## Sprint Breakdown

| Sprint | Focus | Files | Status |
|--------|-------|-------|--------|
| 1 | Core Models, Migrations & SoftDeletable | ~8 files | Pending |
| 2 | Admin Controllers & Routes | ~4 files | Pending |
| 3 | Admin Views (Content Groups & Elements) | ~15 files | Pending |
| 4 | CMS Helper API & Host Integration | ~3 files | Pending |
| 5 | Dashboard Integration & Navigation | ~3 files | Pending |
| 6 | Testing (Fixtures, Model & Request Specs) | ~8 files | Pending |
| 7 | Inline Editing (Future - Stimulus/Turbo) | ~5 files | Future |

## Key Design Decisions

1. **Text-only for MVP**: Content elements support `text` type only initially. Image type is modeled but UI deferred.
2. **No pagination gem**: Use simple offset/limit or Rails built-in `.limit()` to avoid Kaminari dependency.
3. **Author tracking is optional**: Uses `bigint :author_id` like posts, not a required foreign key.
4. **SoftDeletable as engine concern**: Lives in `app/models/concerns/railspress/soft_deletable.rb`.
5. **CMS helper provided as includable module**: Host apps include `Railspress::CmsHelper` in `ApplicationHelper`.
6. **Version history is automatic**: Every save creates a version. No manual versioning.
7. **Inline editing deferred to Sprint 7**: Backend CMS admin comes first.

## File Tree (Final State)

```
app/
├── controllers/railspress/admin/
│   ├── content_groups_controller.rb
│   ├── content_elements_controller.rb
│   └── content_element_versions_controller.rb
├── models/railspress/
│   ├── concerns/
│   │   └── soft_deletable.rb
│   ├── content_group.rb
│   ├── content_element.rb
│   └── content_element_version.rb
├── helpers/railspress/
│   └── cms_helper.rb
└── views/railspress/admin/
    ├── content_groups/
    │   ├── index.html.erb
    │   ├── show.html.erb
    │   ├── new.html.erb
    │   ├── edit.html.erb
    │   └── _form.html.erb
    ├── content_elements/
    │   ├── index.html.erb
    │   ├── show.html.erb
    │   ├── new.html.erb
    │   ├── edit.html.erb
    │   ├── _form.html.erb
    │   └── _inline_form.html.erb (Sprint 7)
    └── content_element_versions/
        └── show.html.erb
db/migrate/
├── YYYYMMDD000001_create_railspress_content_groups.rb
├── YYYYMMDD000002_create_railspress_content_elements.rb
└── YYYYMMDD000003_create_railspress_content_element_versions.rb
spec/
├── fixtures/railspress/
│   ├── content_groups.yml
│   ├── content_elements.yml
│   └── content_element_versions.yml
├── models/railspress/
│   ├── content_group_spec.rb
│   ├── content_element_spec.rb
│   └── content_element_version_spec.rb
└── requests/railspress/admin/
    ├── content_groups_spec.rb
    └── content_elements_spec.rb
```
