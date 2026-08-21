---
title: "Docs: import/export operational accuracy"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Import/export formats, lifecycle, recovery guidance, and operational behavior are documented."
priority: P0
---

# Import/Export Operational Accuracy

## Goal

Correct the post and CMS transfer guide's queue, retry, temporary-file, security, and format semantics so operators do not make unsafe recovery assumptions.

## Audit Findings

- The guide says RailsPress jobs are safe to retry, but post imports create records and increment counters again; export retries also reuse/increment the same status record. There is no idempotency guard.
- Import upload storage now uses opaque server-generated filenames under `tmp/uploads/import_<id>/`; the guide partly reflects the directory but not the loss of original storage names.
- ZIP extraction/export directories are timestamped and cleanup behavior is implementation-specific; the guide presents paths as a durable interface.
- The exact job queues are correctly listed as `default`, but custom queue override guidance should be framed as host-owned and verified against reload behavior.
- The guide's database-schema snippets drift from shipped migrations (for example user fields/counters) and duplicate a model reference that can become stale.
- Admin/API import behavior differs: admin can enqueue multiple uploaded files, API creates one Active Storage-backed import; this distinction is not summarized.

## Documentation Destinations

- Correct `docs/IMPORT_EXPORT.md` as the main guide.
- Add recovery-oriented entries to `docs/TROUBLESHOOTING.md`.
- Cross-link `docs/api/post_imports.md` for API-specific inputs/status polling.

## Plan

1. Replace the retry-safe claim with explicit at-least-once caveats and operator recovery steps: inspect the import/export record and created posts/artifact before retrying.
2. Document admin multi-file upload versus API single attachment/direct-upload flows and their shared status values.
3. Describe temporary storage as internal, ephemeral Rails-root paths; retain useful examples without promising exact names as API.
4. Verify cleanup timing and failure behavior against both jobs/processors, including what remains in Active Storage.
5. Document current SSRF, redirect, ZIP traversal/symlink, extension, and content-type boundaries without implying request-size or decompression limits RailsPress does not implement.
6. Replace copied schema blocks with links to the model reference or regenerate them exactly from migrations.
7. Add queue configuration/monitoring guidance that names the default queue and tells hosts to test any class-level override in their deployment adapter.

## Acceptance Criteria

- The guide does not describe imports or exports as idempotent/retry-safe.
- Admin and API flows are clearly distinguished.
- Temporary-file and cleanup claims match current controller/job/processor code.
- Schema fields in the guide match migrations or are removed in favor of a canonical reference.
- Security claims enumerate implemented controls and do not imply unimplemented availability limits.

## Conventions

- `docs/conventions/integrations/goodjob_patterns.md`
- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/operations/debugging_and_prod_scripts.md`

## Relevant System Documentation

- `app/controllers/railspress/admin/imports_controller.rb`
- `app/jobs/railspress/import_posts_job.rb`
- `app/jobs/railspress/export_posts_job.rb`
- `app/models/railspress/post_import_processor.rb`
- `app/models/railspress/post_export_processor.rb`
- `docs/IMPORT_EXPORT.md`
- `docs/api/post_imports.md`
