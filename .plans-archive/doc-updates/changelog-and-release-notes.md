---
title: "Docs: changelog and release-note completeness"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Changelog, upgrade notes, and release guidance cover the implemented release surface."
priority: P0
---

# Changelog and Release-Note Completeness

## Goal

Ensure the next release notes cover every user-visible addition and give maintainers a repeatable documentation/release checklist.

## Audit Findings

- Unreleased covers doctor, upgrade, and guidance changes but omits format-aware post content writes, literal text import behavior, Post Assets, gallery-image resources, and expanded post/Prime serialization.
- New API documentation exists, but there is no release-level summary telling integrations which capabilities are additive and which responses gained fields.
- The current version remains `1.4.5`; upgrade docs start with “Upgrading to 1.4.5” even though Unreleased behavior is already described as canonical elsewhere.
- `docs/RELEASING.md` does not require docs-link checks, route/API example verification, packaged-doc inspection, doctor smoke testing, or migration-impact notes.

## Documentation Destinations

- Complete `CHANGELOG.md` Unreleased sections.
- Add a version-specific section to `docs/UPGRADING.md` when the target version is selected.
- Strengthen `docs/RELEASING.md`.

## Plan

1. Inventory user-visible changes since the 1.4.5 tag/commit boundary and group them under Added, Changed, Fixed, Deprecated, Security, and Upgrade Notes.
2. Add API notes for new endpoints, response fields/nullability, format behavior, and feature prerequisites.
3. State migration impact explicitly (none/new migrations) and call out any host configuration/dependency/action required.
4. Avoid assigning a release number in prose until `lib/railspress/version.rb` and the release target agree.
5. Extend the release checklist with full RSpec/RuboCop, `bin/rails -T railspress`, doctor smoke test, dummy route verification, local Markdown link check, gem contents inspection, and fresh-host install/upgrade smoke tests.
6. Verify the built gem includes every guide linked from packaged README and CHANGELOG.

## Acceptance Criteria

- Every user-visible file in the Unreleased change set maps to a changelog item or is explicitly internal.
- API consumers can identify additive endpoints/fields and unchanged authentication/version semantics.
- Upgrade notes state configuration, dependency, migration, and deployment impact.
- Release checklist verifies packaged documentation, not only source-tree docs.

## Conventions

- `docs/conventions/operations/bin_scripts_and_tasks.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`

## Relevant System Documentation

- `CHANGELOG.md`
- `docs/RELEASING.md`
- `docs/UPGRADING.md`
- `lib/railspress/version.rb`
- `railspress.gemspec`
- Git history since 1.4.5
