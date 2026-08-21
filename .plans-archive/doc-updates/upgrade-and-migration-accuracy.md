---
title: "Docs: upgrade and migration accuracy"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Upgrade commands, complete migration history, production workflow, and version notes are documented."
priority: P0
---

# Upgrade and Migration Accuracy

## Goal

Make `docs/UPGRADING.md` an accurate, version-aware upgrade guide for the current 18-migration engine rather than a mixture of current workflow and stale migration examples.

## Audit Findings

- The migration catalog stops after API keys and omits taggings/drop cleanup, reading time, focal points, CMS tables, unique/required/image-hint changes, and agent bootstrap keys.
- The text implies a simple incrementing suffix convention even though migrations use multiple date series and intentionally skipped identifiers.
- `create_railspress_post_tags` is listed without explaining that later migrations copy data to polymorphic taggings and drop the old table.
- Commands alternate between `rails` and repository-standard `bin/rails`.
- The duplicate-migration advice says a second migration may have “failed silently,” which is not a safe operational conclusion.
- Production/CI sections later in the file still show the older manual flow without reconciling it with the new source-tree `railspress:upgrade` contract.

## Documentation Destinations

- Rewrite the migration internals and current workflow in `docs/UPGRADING.md`.
- Cross-link the task details to the proposed `docs/MAINTENANCE.md`.
- Keep version-specific notes chronological and leave historical commands explicitly labeled as historical.

## Plan

1. Replace the hand-maintained partial table with a complete current migration inventory grouped by core blog, tagging transition, media, CMS, and Agents & API.
2. Explain semantic-name matching and `.railspress.rb` origin suffixes without promising timestamps match the engine or form an unbroken sequence.
3. Add a migration-impact table for feature flags so operators know which tables are installed even when a feature is disabled.
4. Reconcile Quick Upgrade, step-by-step, CI, and production sections around one canonical decision tree: local/source-tree upgrade task versus committed production migrations.
5. Standardize executable examples on `bin/rails` and use `bundle update railspress-engine` only for dependency selection.
6. Correct rollback/duplicate guidance: inspect migration status and schema first; do not delete an applied migration; explain that destructive/data migrations need version-specific review.
7. Add explicit upgrade notes for the current Unreleased doctor/upgrade and API media/content changes once their target release number is chosen.

## Acceptance Criteria

- Every file in `db/migrate/` is represented or intentionally covered by a generated inventory instruction.
- The guide never recommends deleting an applied migration.
- Production guidance never invokes the source-tree mutating upgrade task.
- Current commands consistently use `bin/rails`.
- Historical upgrade sections do not conflict with the current canonical workflow.

## Conventions

- `docs/conventions/data_layer/schema_conventions.md`
- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`

## Relevant System Documentation

- `db/migrate/`
- `lib/railspress/upgrade.rb`
- `lib/railspress/diagnostics.rb`
- `docs/UPGRADING.md`
- `CHANGELOG.md`
