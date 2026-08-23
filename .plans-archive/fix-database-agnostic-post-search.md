---
title: "fix: database-agnostic post title search"
type: fix
created: 2026-08-18
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Adapter-portable case-insensitive Post title search and behavioral specs are present."
---

# Database-Agnostic Post Title Search

## Goal

Make `Railspress::Post.search(query)` work across Active Record-supported database adapters without changing its public API or case-insensitive substring behavior.

## Context

The engine currently embeds PostgreSQL-only `ILIKE` SQL in the `Post.search` scope. The admin posts index always calls this scope, so entering a search term fails on SQLite and MySQL hosts. The dummy application and test suite use SQLite, but the scope has no direct behavioral coverage.

## Scope Boundaries

In scope:

- Replace the title predicate with adapter-aware Arel.
- Add model specs for matching, case insensitivity, non-matches, and blank input.
- Update the model reference and generic blogging examples so they do not teach PostgreSQL-only SQL.
- Update the changelog and bump the gem patch version from `1.4.2` to `1.4.3`.

Out of scope:

- Adding body, slug, fuzzy, ranked, or full-text search to the engine API.
- Changing the admin search UI or controller API.
- Removing the explicitly labeled optional PostgreSQL full-text-search recipe.
- Auditing unrelated sorting or query code for adapter portability.
- Publishing, tagging, pushing, or releasing the gem.

## Key Technical Decisions

- Build the predicate with `arel_table[:title].matches(pattern, nil, false)`. The final `false` requests case-insensitive matching and lets the active adapter choose its SQL representation.
- Preserve the existing substring pattern and blank-query behavior; do not introduce a search service or adapter conditionals.
- Treat this as a patch release because it is a backward-compatible bug fix under Semantic Versioning.
- Test observable query results on the repository's SQLite test adapter rather than asserting generated SQL.

## Plan

1. Update `Railspress::Post.search` to use Arel's adapter-aware case-insensitive match predicate.
2. Add focused model scope examples using existing post fixtures.
3. Replace generic `ILIKE` documentation and sample-fixture snippets with the portable scope/API pattern.
4. Add a `Fixed` entry under `Unreleased`, bump `Railspress::VERSION` to `1.4.3`, and refresh the lockfile metadata.
5. Run the focused model spec, lint touched Ruby files, then run the full RSpec suite if focused verification passes.

## Acceptance Criteria

- Searching by a partial title works on the SQLite-backed test suite.
- Search remains case-insensitive.
- Nonmatching input returns no posts.
- Blank input leaves the relation unfiltered and chainable.
- No PostgreSQL-specific SQL remains in engine runtime code or generic search documentation.
- The gem reports version `1.4.3`, and the changelog records the portability fix.

## Open Questions

None.

## Conventions

- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/model_specs.md`

## Relevant System Documentation

- `docs/README.md`
- `docs/BLOGGING.md`
- `docs/RELEASING.md`
- `CHANGELOG.md`
