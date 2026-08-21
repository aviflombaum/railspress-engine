---
title: "Docs: automated drift guards"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Documentation contracts cover links and synchronized public inventories and pass in the suite."
priority: P2
---

# Automated Documentation Drift Guards

## Goal

Add lightweight verification that catches the kinds of documentation drift found in this audit before release.

## Audit Findings

The current suite can pass while docs contain nonexistent route helpers, stale CSS tokens, old associations, broken local commands, and API examples missing returned keys. Documentation is packaged with the gem, so these are shipped product defects rather than repository-only prose issues.

## Scope Boundaries

In scope: deterministic local checks for links, routes, configuration coverage, CSS tokens, task inventory, and selected JSON examples.

Out of scope: executing every shell snippet, provisioning external services, screenshot testing the full documentation site, or building a general-purpose documentation framework.

## Plan

1. Add a local Markdown-link checker for README, CHANGELOG, and `docs/**/*.md`, ignoring example placeholders intentionally.
2. Add a spec or script that validates documented host route helpers against the dummy app route proxy.
3. Add a CSS-token parity check between the canonical token table and `variables.css`; prefer generating the table if that remains readable.
4. Add a configuration coverage test mapping intended-public `Configuration` options to headings in `docs/CONFIGURING.md`.
5. Add a Rake task inventory assertion for the maintenance guide.
6. Validate selected API response examples (Prime and serialized Post/media) from fixtures/spec responses rather than duplicating hand-written hashes where feasible.
7. Wire the fast checks into the existing test/CI workflow and document how to update intentional changes.

## Acceptance Criteria

- A renamed route helper, CSS token, configuration option, or maintenance task causes a focused actionable failure.
- Local links in packaged docs are validated.
- Checks do not require network access or mutate the committed dummy database.
- Generated/validated sections remain human-readable in the packaged gem.
- Intentional exceptions are explicit and narrow.

## Conventions

- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
- `docs/conventions/operations/bin_scripts_and_tasks.md`

## Relevant System Documentation

- `spec/dummy/`
- `config/routes.rb`
- `lib/railspress.rb`
- `lib/tasks/`
- `app/assets/stylesheets/railspress/admin/variables.css`
- `docs/`
