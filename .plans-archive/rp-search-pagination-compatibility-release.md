---
title: "feat: namespace engine search and pagination APIs"
type: feat
created: 2026-08-18
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Namespaced search/pagination APIs, compatibility deprecations, engine callers, docs, and specs are present in the released version line."
---

# Namespace Engine Search and Pagination APIs

## Goal

Give RailsPress stable, dependency-free search and pagination methods that cannot be confused with host-application or third-party APIs, while preserving existing applications through a deprecation period and preparing a `1.4.3` release.

The permanent RailsPress-owned API will be:

- `rp_search(query)` for the built-in case-insensitive post-title search
- `rp_page(page_number)` for the built-in offset/limit pagination
- `rp_per_page_count` for resolving the built-in page size

Engine code will use only these `rp_*` methods. Host applications remain free to use `search`, Kaminari's `page(...).per(...)`, Pagy, will_paginate, Searchkick, `pg_search`, or custom query objects in their own controllers.

## Context

RailsPress currently exposes generic methods that can collide with host stacks:

- `Railspress::Post.search(query)` is called by the admin posts index.
- `Railspress::Entity.page(page_number)` and `per_page_count` are mixed into every registered entity as class/relation APIs.
- The admin posts index calls `page` and reads `Post::PER_PAGE` directly.
- The posts API uses `per_page_count` for its default and invalid-value fallback.
- Documentation currently recommends load-order manipulation when Kaminari's `page` conflicts with RailsPress.

The uncommitted database-portability work already replaces PostgreSQL-only `ILIKE` in the built-in title search with adapter-aware Arel, adds behavioral coverage, updates generic search documentation, and sets the version to `1.4.3`. This plan incorporates that work into the same patch release; it must be preserved rather than recreated or discarded.

Rails initialization does not provide a reliable universal "last method definition" point across lazy loading, eager loading, reloads, host decorators, and arbitrary gems. RailsPress therefore avoids depending on load order for its own behavior. Its admin uses `rp_*`, and the generic names exist only as best-effort compatibility fallbacks.

## Scope Boundaries

### In scope

- Add `rp_search`, `rp_page`, and `rp_per_page_count` as the canonical RailsPress query APIs.
- Keep `PER_PAGE = 20` and per-model `PER_PAGE` overrides as the built-in page-size configuration.
- Change all engine-owned search and pagination call sites to use the `rp_*` APIs.
- Add conditional compatibility methods for `search`, `page`, and `per_page_count` only when those names are not already available.
- Emit RailsPress-owned deprecation warnings when compatibility methods are used, with removal targeted for `2.0`.
- Register a RailsPress deprecator with the host application's deprecator collection so normal Rails deprecation configuration applies.
- Add focused behavior and compatibility specs without installing or testing a matrix of pagination/search gems.
- Update user documentation, upgrading guidance, code samples, changelog, gem version, and lockfile.
- Run the repository verification workflow and build/inspect the `1.4.3` gem artifact.
- Prepare the exact release checklist and commands for commit, push, tag, gem publication, and GitHub release.

### Out of scope

- Adding a `.per` relation method.
- Reimplementing Kaminari, Pagy, will_paginate, Searchkick, or `pg_search` behavior.
- Making RailsPress admin search or pagination configurable through callbacks.
- Allowing hosts to override `rp_search`, `rp_page`, or `rp_per_page_count`; these names are reserved for RailsPress internals.
- Changing API request parameters (`page` and `per`) or response pagination metadata.
- Adding full-text, body, slug, fuzzy, or ranked search to the engine default.
- Removing the legacy method names before `2.0`.
- Publishing the gem, pushing commits/tags, or creating a GitHub release without a separate explicit release confirmation.

## Key Technical Decisions

### 1. RailsPress owns the `rp_*` namespace

The engine admin and API must call only `rp_search`, `rp_page`, and `rp_per_page_count`. These methods provide predictable baseline behavior regardless of methods added by the host or another gem.

Host applications should not override the `rp_*` methods. Public host controllers should use whichever search and pagination APIs fit their stack.

### 2. Keep pagination deliberately small

`rp_page(page_number)` will preserve the existing behavior:

1. Convert the input to an integer.
2. Clamp the page number to at least `1`.
3. Apply `offset((page_number - 1) * rp_per_page_count)`.
4. Apply `limit(rp_per_page_count)`.

`rp_per_page_count` will preserve the existing resolution rule:

- Use a model's directly defined `PER_PAGE` constant when present.
- Otherwise use `Railspress::Entity::PER_PAGE`, currently `20`.

RailsPress will not define `.per`; pagination gems retain ownership of their richer APIs.

### 3. Preserve search behavior while namespacing it

Move the adapter-aware Arel predicate from `Post.search` to `Post.rp_search`. Preserve:

- Case-insensitive title matching
- Substring matching
- An ordinary chainable `ActiveRecord::Relation`
- An unfiltered relation for blank input

The admin posts controller will call `rp_search`, so a host's `search` method cannot alter engine-admin behavior.

### 4. Compatibility methods are conditional fallbacks

For the remainder of the `1.x` series:

- Define `search` only when the model does not already respond to `search`.
- Define `page` only when the model does not already respond to `page`.
- Define `per_page_count` only when the model does not already respond to `per_page_count`.
- Each fallback delegates to its `rp_*` equivalent and emits a deprecation warning naming the replacement and the `2.0` removal horizon.
- A host method declared after RailsPress setup remains free to replace the compatibility fallback through normal Ruby/Active Record method definition.

This is a migration aid, not the architectural collision solution. The collision solution is that engine internals no longer use generic method names.

### 5. Use a RailsPress-owned deprecator

Expose `Railspress.deprecator` backed by:

```ruby
ActiveSupport::Deprecation.new("2.0", "RailsPress")
```

Register it in the engine initializer as `app.deprecators[:railspress]`. This follows Rails' gem/engine guidance and allows host settings such as `config.active_support.deprecation` and `report_deprecations` to govern RailsPress warnings.

Compatibility wrappers should call `Railspress.deprecator.warn` directly. Do not use the global Rails deprecator.

### 6. Target version `1.4.3`

This is a compatibility bug-fix release: it removes database-vendor-specific SQL and prevents engine internals from colliding with host search and pagination methods. The namespaced APIs are the stable internal entry points needed to deliver that fix, while the existing generic APIs remain available through conditional compatibility wrappers. The target is therefore patch release `1.4.3`.

Legacy APIs remain callable in `1.4.3`; their eventual removal is reserved for `2.0.0`.

## Implementation Plan

### Unit 1: Add the RailsPress deprecator

Files:

- `lib/railspress.rb`
- `lib/railspress/engine.rb`
- Relevant engine/lib spec

Work:

1. Require the appropriate Active Support deprecation API if it is not already loaded by the entrypoint.
2. Add a memoized `Railspress.deprecator` with a `2.0` horizon and `RailsPress` gem name.
3. Register it under `:railspress` in an engine initializer.
4. Keep initializer behavior idempotent and avoid forcing reloadable application model constants to load during boot.

Acceptance:

- The deprecator reports the correct gem name and removal horizon.
- The engine registers the same deprecator object with the application collection.

### Unit 2: Namespace Entity pagination

File:

- `lib/railspress/entity.rb`

Work:

1. Rename the canonical implementation from `page` to `rp_page`.
2. Rename page-size resolution from `per_page_count` to `rp_per_page_count`.
3. Make `rp_page` call `rp_per_page_count` for both offset and limit.
4. Preserve `PER_PAGE = 20` and direct model constant overrides.
5. Install deprecated `page` and `per_page_count` wrappers only when those methods are absent.
6. Keep every pagination path relation-returning and chainable.

Acceptance:

- `Project.ordered.rp_page(2)` applies the expected offset and limit.
- Invalid/zero/negative page input clamps to the first page.
- A model-defined `PER_PAGE` changes `rp_per_page_count` and `rp_page` behavior.
- Existing `page` or `per_page_count` methods are not overwritten.
- Fallback methods delegate correctly and warn.

### Unit 3: Namespace post search

File:

- `app/models/railspress/post.rb`

Work:

1. Rename the canonical Arel scope to `rp_search`.
2. Add a conditional deprecated `search` compatibility scope/wrapper.
3. Preserve the current portable Arel implementation and blank-query behavior.

Acceptance:

- `rp_search` passes the partial, case-insensitive, nonmatching, and blank cases already added by the portability work.
- The legacy `search` fallback produces the same records and warns.
- The result remains chainable with publication, category, status, sorting, and pagination relations.

### Unit 4: Migrate engine-owned callers

Files:

- `app/controllers/railspress/admin/posts_controller.rb`
- `app/controllers/railspress/api/v1/posts_controller.rb`
- Any additional engine-owned call sites found by a final `rg` inventory

Work:

1. Change admin title filtering from `search` to `rp_search`.
2. Change admin pagination from `page` to `rp_page`.
3. Calculate admin total pages with `Post.rp_per_page_count`, not `Post::PER_PAGE`, so the controller uses the same resolved page size as the relation.
4. Change API default/fallback page-size reads from `per_page_count` to `rp_per_page_count`.
5. Leave API's client-selectable `per` parameter, upper cap, explicit `offset`, and response metadata unchanged.

Acceptance:

- Engine requests do not invoke deprecated compatibility methods.
- Admin search and pagination retain existing output.
- API pagination metadata and limits retain existing behavior.

### Unit 5: Add focused compatibility coverage

Files:

- `spec/models/railspress/post_spec.rb`
- `spec/lib/railspress/entity_spec.rb`
- `spec/lib/railspress/engine_spec.rb` or the most focused existing lib/engine spec
- Existing admin/API request specs only where an observable engine regression is otherwise uncovered

Test cases:

#### Post search

- `rp_search` finds a partial title.
- `rp_search` is case-insensitive on the SQLite test adapter.
- `rp_search` excludes nonmatches.
- `rp_search` leaves a blank query unfiltered.
- Deprecated `search` delegates to `rp_search` and emits a RailsPress deprecation.

#### Entity pagination

- `rp_page(1)` applies the resolved limit with zero offset.
- `rp_page(2)` applies the correct offset.
- Invalid page input clamps to page one.
- A model-local `PER_PAGE` is returned by `rp_per_page_count` and used by `rp_page`.
- Deprecated `page` delegates and warns when no competing method exists.
- Deprecated `per_page_count` delegates and warns when no competing method exists.
- A class with `page` defined before including `Railspress::Entity` keeps its own method.
- A class with `per_page_count` defined before inclusion keeps its own method.
- A class method defined after inclusion can replace the compatibility fallback.

#### Deprecator and engine wiring

- `Railspress.deprecator` has the `2.0` horizon and RailsPress identity.
- The engine registers it with the application deprecator collection.

Testing constraints:

- Use existing fixtures/tables and anonymous Active Record classes where necessary; add no testing gems.
- Test observable relation behavior and method precedence, not Ruby ancestor internals.
- Spy on the RailsPress deprecator only where verifying the outgoing warning command.
- Do not add Kaminari, Pagy, will_paginate, or search-gem integration matrices. The supported contract is non-clobbering and namespaced engine behavior, independent of a particular gem.
- Run all RSpec commands through `bin/agent-rspec`.

### Unit 6: Update documentation and samples

Files:

- `docs/README.md`
- `docs/BLOGGING.md`
- `docs/ENTITIES.md`
- `docs/UPGRADING.md`
- `spec/fixtures/files/markdown_samples/12_kitchen_sink.md`
- Any root README references found by the final inventory

Work:

1. Document `rp_search` as RailsPress's simple, portable title-search default.
2. Document `rp_page` and `rp_per_page_count` as RailsPress-owned baseline pagination.
3. Explain that `PER_PAGE` remains the built-in page-size override and that RailsPress does not provide `.per`.
4. Update engine/default examples to use `rp_*` methods.
5. Replace the current Kaminari load-order workaround with straightforward guidance:
   - RailsPress admin uses `rp_*` and does not conflict.
   - Host controllers may use Kaminari's `page(...).per(...)`, Pagy, will_paginate, or manual pagination.
   - Generic compatibility names are deprecated and should not be used in new code.
6. Add `1.4.3` upgrading guidance covering:
   - No required migration or initializer changes.
   - Existing `search`, `page`, and `per_page_count` calls continue temporarily when not supplied by the host.
   - Migrate RailsPress-default calls to `rp_*` or use the host stack's APIs.
   - Legacy fallback removal is planned for `2.0`.
7. Preserve the explicitly labeled PostgreSQL full-text-search recipe as an optional host-specific example.

Acceptance:

- Generic RailsPress examples contain no PostgreSQL-only title-search SQL.
- No documentation recommends manipulating gem require order.
- The distinction between engine defaults and host-owned search/pagination is explicit.

### Unit 7: Prepare the `1.4.3` release metadata

Files:

- `lib/railspress/version.rb`
- `Gemfile.lock`
- `CHANGELOG.md`

Work:

1. Confirm the in-progress version is `1.4.3`.
2. Refresh the lockfile with `bundle lock` and verify only intended dependency metadata changes.
3. Expand the changelog under appropriate headings:
   - `Added`: canonical `rp_search`, `rp_page`, and `rp_per_page_count` APIs.
   - `Deprecated`: conditional `search`, `page`, and `per_page_count` fallbacks, removed in `2.0`.
   - `Fixed`: database-agnostic built-in title search and pagination/search method collisions inside engine-owned code.
4. Add concise upgrade notes with no migration requirement.
5. At final release preparation, convert the accumulated entry into a dated `[1.4.3]` section while retaining an empty `[Unreleased]` heading.

### Unit 8: Verification and artifact preparation

Follow the repository's RSpec and release workflows:

1. Before implementation, capture `bin/agent-rspec baseline rp-search-pagination-compatibility` now that dependencies are installed.
2. During development, run focused specs through `bin/agent-rspec run` after each implementation unit.
3. Run RuboCop on touched Ruby files.
4. Run `bin/agent-rspec post rp-search-pagination-compatibility` and `bin/agent-rspec diff rp-search-pagination-compatibility`.
5. Resolve all failures attributed to changed code/specs; document only genuinely pre-existing failures according to the testing workflow.
6. Run full `bin/rubocop` and `git diff --check`.
7. Run `bundle lock` and verify the lockfile diff.
8. Build `railspress-engine-1.4.3.gem` with the documented gem build command.
9. Inspect the built gem specification and file list to confirm:
   - Version is `1.4.3`.
   - Runtime files, documentation, changelog, and migrations expected by the gemspec are present.
   - Development-only files and unintended artifacts are absent according to the gemspec.
10. Do not publish yet. Record the artifact path and checksum for the release handoff.

### Unit 9: Gated release execution

Perform this unit only after presenting verification results and receiving explicit confirmation to publish:

1. Confirm the working tree contains only intended release changes.
2. Commit with the repository's release subject convention, such as `release: prepare v1.4.3`.
3. Push the release commit to the intended remote branch.
4. Publish the exact verified `.gem` artifact to RubyGems.
5. Create and push annotated or repository-conventional tag `v1.4.3` at the release commit.
6. Create the GitHub release from the `1.4.3` changelog notes.
7. Verify the RubyGems version and GitHub tag/release resolve publicly.
8. Smoke-test installation in a fresh Rails app according to `docs/RELEASING.md`.

Before any external mutation, re-resolve the branch, remote, RubyGems identity, artifact checksum, and tag target. Never rebuild a different artifact between approval and publication.

## Documentation Matrix

| Audience | Document | Required message |
|---|---|---|
| Engine users | `docs/README.md` | `rp_search` is the simple portable default |
| Blog builders | `docs/BLOGGING.md` | Host search/pagination is application-owned; `rp_*` examples show the no-gem baseline |
| Entity authors | `docs/ENTITIES.md` | `rp_page`, `rp_per_page_count`, and `PER_PAGE` behavior |
| Upgraders | `docs/UPGRADING.md` | Compatibility period, deprecations, and `2.0` removal horizon |
| Release consumers | `CHANGELOG.md` | Added/deprecated/fixed entries plus migration impact |
| Import fixture coverage | Markdown kitchen-sink fixture | Portable and current `rp_search` sample |

## Release Acceptance Criteria

- All engine-owned post search uses `rp_search`.
- All engine-owned built-in pagination uses `rp_page` and `rp_per_page_count` where applicable.
- RailsPress no longer requires or recommends load-order manipulation for Kaminari.
- Host-defined generic methods are not intentionally overwritten by compatibility setup.
- Legacy generic methods continue to work with deprecation warnings when no competing method exists.
- Search remains database-adapter portable and behaviorally verified on SQLite.
- No new search or pagination dependency is added.
- Version, lockfile, changelog, upgrading guide, and built gem all agree on `1.4.3`.
- Focused specs, full suite comparison, full RuboCop, and diff checks pass.
- The gem artifact is built and inspected but not externally published without explicit approval.

## Risks and Mitigations

### Active Record method-generation precedence

Risk: scopes and gem extensions can define class/relation methods through different mechanisms.

Mitigation: reserve `rp_*` for all engine behavior; treat generic wrappers as temporary best-effort fallbacks; test methods present before inclusion and replacements defined afterward without asserting internal ancestor order.

### Development reload behavior

Risk: compatibility or deprecator wiring could be applied more than once.

Mitigation: keep the deprecator memoized, initializer registration idempotent, and compatibility method definitions local to model/concern loading rather than forcing model loading from initialization hooks.

### Accidental behavior change in API pagination

Risk: renaming `per_page_count` could alter the API's `per` default or maximum.

Mitigation: change only the default/fallback method call; retain request parsing, `100` cap, offset/limit calculation, and response metadata, with existing request specs run in full.

### Release scope confusion

Risk: the existing `1.4.3` portability changes could be released separately or overwritten.

Mitigation: explicitly fold them into `1.4.3`, review the complete working-tree diff, and produce one changelog/release artifact containing both portability and namespaced API work.

## Open Questions

None. The implementation can proceed from this plan.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/concerns.md`
- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/model_specs.md`
- `docs/conventions/testing/rspec/request_specs.md`
- `docs/conventions/operations/bin_scripts_and_tasks.md`

## Relevant System Documentation and Research

- `docs/README.md`
- `docs/BLOGGING.md`
- `docs/ENTITIES.md`
- `docs/UPGRADING.md`
- `docs/RELEASING.md`
- `CHANGELOG.md`
- Rails Active Support deprecator guidance: use a gem-owned deprecator and register it with the application's deprecator collection.
- Rails engine/reloading guidance: avoid relying on a universal late-load hook; use namespaced APIs and reload-safe, idempotent setup.
- Kaminari guidance: its `page` method is configurable specifically to avoid naming conflicts, while `.per` belongs to the paginated relation.
