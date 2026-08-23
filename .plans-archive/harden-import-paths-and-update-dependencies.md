---
title: "fix: contain import paths and update vulnerable dependencies"
type: fix
created: 2026-08-18
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Upload/cleanup/archive path containment, focused regressions, and patched lockfile dependencies are present."
---

# Contain Import Paths and Update Vulnerable Dependencies

## Goal

Keep every post-import file write, cleanup, and ZIP image read inside RailsPress-owned temporary directories, then update the development lockfile to patched `rails-html-sanitizer` and `json` versions.

## Context

RailsPress admin imports are restricted to trusted host-application administrators, so these findings are Medium or Low under the intended threat model. Filesystem containment remains the highest-value engine improvement because an import operation should not inherit the Rails process's broader filesystem authority.

The admin importer currently uses the client-provided `original_filename` as a path component. ZIP post imports also expand frontmatter image paths without confirming that the resulting real path remains inside the extraction root. The repository lockfile selects two transitive dependencies with published advisories even though RailsPress does not directly declare or use their affected APIs.

## Scope Boundaries

### In scope

- Generate server-controlled filenames for admin post-import uploads.
- Preserve the client filename only as import display metadata.
- Canonicalize cleanup paths before deciding whether they are safe to remove.
- Resolve ZIP-referenced post images only when their real path remains inside the extraction root.
- Reject absolute, traversal, and symlink-escape image references through containment rather than special-case string matching.
- Add one focused regression example for each filesystem boundary.
- Update `rails-html-sanitizer` to `1.7.1+` and `json` to `2.21.2+` in `Gemfile.lock` using conservative Bundler resolution.
- Run Bundler Audit after the update.

### Out of scope

- Changing the documented unauthenticated-admin integration model.
- Disabling or hardening remote HTTP image fetching.
- Adding archive size, entry, or processing-time limits.
- Redesigning the import job arguments or queue architecture.
- Changing supported import extensions or user-visible import behavior.
- Bootstrap-key lifecycle changes.
- Version bumps, changelog entries, publishing, commits, or pushes.

## Key Technical Decisions

### 1. Client filenames are metadata, not storage paths

The `Import` record continues to display `original_filename`, but the controller writes each upload under a random server-generated basename. Only an existing supported extension is retained so `PostImportProcessor` can dispatch by file type.

### 2. Canonical paths establish the boundary

String prefix checks on unresolved paths are insufficient. Cleanup will expand both the trusted temporary root and candidate path, then require the candidate to be a descendant of that root using a path-separator-aware comparison.

### 3. ZIP image references must remain inside the real extraction root

The processor will consider the existing lookup order—relative to the Markdown file, then relative to the archive root—but accept a candidate only when:

- It is a regular file.
- Its real path is under the extraction root's real path.
- Its extension remains one of the existing supported image extensions.

Using real paths also blocks symlinks inside the archive tree from escaping the boundary.

### 4. Do not add direct gemspec pins for transitive advisories

`rails-html-sanitizer` is resolved through Rails `actionpack`/`actionview`, and `json` through `activesupport` (plus development RuboCop). The RailsPress gemspec does not force the vulnerable versions. Update the repository lockfile without adding redundant direct runtime dependencies.

## Implementation Plan

### Unit 1: Contain admin upload writes and cleanup

Files:

- `app/controllers/railspress/admin/imports_controller.rb`
- `app/jobs/railspress/import_posts_job.rb`
- `spec/requests/railspress/admin/imports_spec.rb`
- `spec/jobs/railspress/import_posts_job_spec.rb`

Work:

1. Retain the original upload name only on the `Import` record.
2. Generate a random filename for each stored upload while preserving a supported extension.
3. Expand cleanup candidates before enforcing the Rails `tmp` descendant boundary.
4. Add a request regression proving an absolute client filename cannot select its destination.
5. Add a job regression proving a lexically `tmp`-prefixed traversal path cannot delete a file outside `tmp`.

### Unit 2: Contain ZIP image reads

Files:

- `app/models/railspress/post_import_processor.rb`
- `spec/models/railspress/post_import_processor_spec.rb`

Work:

1. Preserve relative-to-Markdown then relative-to-root lookup behavior.
2. Resolve candidate and root real paths.
3. Reject candidates outside the root, including absolute paths, traversal, and symlink escapes.
4. Add one public-behavior regression proving an absolute local image path is not attached from a ZIP import.

### Unit 3: Update transitive dependencies

File:

- `Gemfile.lock`

Work:

1. Conservatively update only `rails-html-sanitizer` and `json` plus unavoidable resolver metadata.
2. Confirm patched minimum versions.
3. Run Bundler Audit with the current advisory database.

## Minimal Test Strategy

- One request example for server-controlled upload storage.
- One job example for canonical cleanup containment.
- One model example for ZIP image read containment.
- Existing import examples provide happy-path coverage and should remain unchanged.
- No exhaustive traversal-input matrix or new testing dependency.

## Verification

1. Capture an `agent-rspec` baseline before source changes.
2. Run the three touched spec files in development mode with fail-fast behavior.
3. Run RuboCop on touched Ruby/spec files.
4. Run `bundler-audit check --update`.
5. Run `agent-rspec` post and diff validation.

## Acceptance Criteria

- Client filenames cannot determine an admin import's filesystem destination.
- Cleanup cannot delete a path that resolves outside `Rails.root/tmp`.
- ZIP frontmatter cannot attach an image whose real path is outside the extraction root.
- Existing valid post ZIP imports and header-image attachments still pass.
- `Gemfile.lock` resolves `rails-html-sanitizer >= 1.7.1` and `json >= 2.21.2`.
- Bundler Audit reports no advisory for either package.
- Focused regression specs pass and post-work comparison introduces no related failures.

## Open Questions

None.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
- `docs/conventions/testing/rspec/model_specs.md`
- `docs/conventions/testing/rspec/job_specs.md`

## Relevant System Documentation

- `docs/IMPORT_EXPORT.md`
- `tmp/security-audit-8-18-26.md`
