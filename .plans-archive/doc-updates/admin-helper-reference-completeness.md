---
title: "Docs: complete the admin helper reference"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Public admin helper documentation and documentation-contract coverage are present."
priority: P1
---

# Complete the Admin Helper Reference

## Goal

Turn `docs/ADMIN_HELPERS.md` into a complete, signature-accurate customization reference for the public helpers host view overrides are expected to use.

## Audit Findings

The guide covers common fields and layout helpers but has no entry for current helpers including:

- `rp_focal_point_image_field`
- `rp_edit_icon`, `rp_delete_icon`, `rp_table_action_icons`, `rp_icon`
- `rp_flash_messages`, `rp_page_title`
- `rp_form_group`, `rp_form_actions`
- `rp_badge`, `rp_author_display`, `rp_hint`
- `rp_input_class`, `rp_label_class`, `rp_table_header`

Several are important for keeping overridden admin views consistent with current markup, disabled-delete behavior, author fallback rules, focal-point editing, and sortable/action tables.

## Documentation Destinations

- Expand `docs/ADMIN_HELPERS.md` as the reference.
- Keep `docs/CONFIGURING.md` view-override examples short and link to the relevant helper sections.
- Add only user-facing customization helpers; clearly label low-level class-building helpers as advanced.

## Plan

1. Inventory every `rp_*` method in `AdminHelper` and `ApplicationHelper` and classify it as public customization API, advanced building block, or internal-only.
2. For public methods, document the exact signature, defaults, return/output behavior, required record/form state, and a minimal ERB example.
3. Add focused sections for focal images, table actions/icons, flash/page layout, form composition, author display fallback, and CSS-class builders.
4. Document noteworthy edge behavior: disabled delete controls, persisted-record requirement for focal editing, `nil` author handling, allowed icon names, and unknown-icon output.
5. Cross-link the focal point, entities, theming, and view override guides.
6. Add a maintenance checklist so helper additions/removals update this reference in the same change.

## Acceptance Criteria

- Every intended-public `rp_*` helper has one searchable heading or reference-table entry.
- Signatures/defaults match `app/helpers/railspress/*.rb`.
- Examples use current `rp-` markup and Turbo confirmation conventions.
- Internal helpers are not accidentally promised as stable without being labeled.

## Conventions

- `docs/conventions/frontend/admin_ui_patterns.md`
- `docs/conventions/frontend/forms.md`
- `docs/conventions/frontend/layouts_and_views.md`
- `docs/conventions/frontend/tables.md`

## Relevant System Documentation

- `app/helpers/railspress/admin_helper.rb`
- `app/helpers/railspress/application_helper.rb`
- `docs/ADMIN_HELPERS.md`
- `docs/CONFIGURING.md`
