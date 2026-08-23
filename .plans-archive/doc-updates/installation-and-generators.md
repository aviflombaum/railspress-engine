---
title: "Docs: installation and generator behavior"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Install/entity generator behavior, rerun semantics, and migration workflow are documented."
priority: P1
---

# Installation and Generator Behavior

## Goal

Document what the install and entity generators actually create or modify, how reruns/upgrades are detected, and what the host must do afterward.

## Audit Findings

- README shows both manual Action Text/Active Storage installation and the RailsPress install generator, but does not explain that the generator conditionally copies those migrations itself.
- The install generator mutates routes, migrations, importmap, and initializer; its idempotent skip behavior is not summarized.
- Existing-install detection changes the generator's message and then points to `railspress:upgrade`; this distinction is not documented for operators deciding which command to run.
- The entity generator is only shown as a one-line command. Supported Rails attribute types, generated `has_rich_text`, generated migration/model registration, unsupported/advanced fields, restart requirement, and namespaced model considerations are absent.
- Examples mix `rails generate` and `bin/rails generate`.

## Documentation Destinations

- Expand the Installation and Generators sections in `README.md`.
- Add an “Install generator” section to `docs/CONFIGURING.md`.
- Add an “Entity generator” section near Quick Start in `docs/ENTITIES.md`.
- Add rerun/partial-install recovery to `docs/TROUBLESHOOTING.md`.

## Plan

1. Add a generated-files table for `railspress:install`: RailsPress, Action Text, and Active Storage migrations; engine mount; importmap Active Storage pin when importmap exists; initializer template.
2. Explain skip/idempotency behavior and state that the generator does not run `db:migrate`, write encryption credentials, or enable opt-in features.
3. Clarify new install versus existing-install/upgrade usage, linking existing apps to doctor/upgrade rather than presenting generator reruns as the only upgrade path.
4. Document the initializer template's feature sections and the required admin authentication review before deployment.
5. Document `railspress:entity NAME field:type...`, including output files, automatic registration, rich-text handling, schema-supported type detection, and manual DSL follow-up for attachments, arrays, focal images, labels, and index columns.
6. Use `bin/rails generate ...` consistently and include verification commands/routes.

## Acceptance Criteria

- A user can predict every file the generators touch before running them.
- The docs distinguish copying migrations from applying migrations.
- API encryption guidance clearly states the generator only detects/reports configuration.
- Entity generator examples match its templates and supported argument behavior.
- Rerunning a generator is not presented as a substitute for reviewing upgrades.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/data_layer/schema_conventions.md`

## Relevant System Documentation

- `lib/generators/railspress/install/install_generator.rb`
- `lib/generators/railspress/install/templates/initializer.rb`
- `lib/generators/railspress/entity/entity_generator.rb`
- `lib/generators/railspress/entity/templates/`
- `README.md`
- `docs/CONFIGURING.md`
- `docs/ENTITIES.md`
