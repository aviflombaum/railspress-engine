---
title: "Docs: model and route reference corrections"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Model, association, route, helper, and feature-gating references match the runtime surface."
priority: P0
---

# Model and Route Reference Corrections

## Goal

Correct `docs/README.md` so its model attributes, associations, methods, paths, and route helpers reflect the current schema and Rails route set.

## Audit Findings

- `Railspress::Post` is documented with nonexistent `excerpt` and `author_type` columns.
- Author assignment is described as polymorphic, but Post stores only `author_id` and resolves the configured author class.
- Post/Tag associations still say `through post_tags`; current code uses polymorphic `Railspress::Tagging` and the old table is dropped.
- `ContentGroup#element_count` is presented as a stored integer/counter cache but is a computed method over active elements.
- `ContentElementVersion#changes_from_previous` is presented as a text attribute but is a computed hash; actual persisted fields such as `text_content` and `version_number` need correction.
- Scheduled/live/display-status behavior and gallery attachments are incompletely represented.
- `/railspress/admin/cms_transfers` is wrong; the singular resource is `/railspress/admin/cms_transfer`.
- `admin_entity_new_path` and `admin_entity_edit_path` do not exist. Rails generates `admin_new_entity_path` and `admin_edit_entity_path`.
- `admin_cms_transfer_path` is shown returning the wrong plural URL.

## Documentation Destinations

- Correct the model and route reference in `docs/README.md`.
- Correct any repeated association/path claims in `docs/ENTITIES.md`, `BLOGGING.md`, and `IMPORT_EXPORT.md`.
- Keep conceptual guides concise and link back to the corrected reference.

## Plan

1. Build the model tables from migrations plus public model APIs, explicitly distinguishing database columns, Active Storage/Action Text associations, virtual attributes, and computed methods.
2. Replace old tagging terminology with `taggings`, including the polymorphic reuse story.
3. Describe configured author lookup accurately and remove `author_type`/polymorphic claims for Post and CMS content.
4. Add current Post scheduling predicates/scopes (`scheduled`, `live`, `scheduled?`, `live?`, `display_status`) where they are public and useful.
5. Regenerate the route helper/path table from `bin/rails routes` against the dummy app.
6. Label engine-internal controller helpers (`entity_new_path`, etc.) separately from host-callable route proxy helpers.
7. Correct the gem lookup command from `bundle show railspress` to `bundle show railspress-engine` wherever source paths are shown.

## Acceptance Criteria

- Every documented column exists in a shipped migration and every computed value is labeled as such.
- No current docs describe Post authors as polymorphic or tags as using `post_tags`.
- Every documented route helper resolves in the dummy application's mounted engine.
- Singular/plural CMS transfer URLs match `config/routes.rb`.
- Source lookup examples use the actual gem name.

## Conventions

- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/domain/route_naming.md`

## Relevant System Documentation

- `docs/README.md`
- `app/models/railspress/`
- `app/models/concerns/railspress/`
- `db/migrate/`
- `config/routes.rb`
- `app/controllers/railspress/admin/entities_controller.rb`
