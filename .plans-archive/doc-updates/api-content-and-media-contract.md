---
title: "Docs: API content and media contract"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "API content, media, gallery, focal-point, and serialization contracts are documented and guarded."
priority: P0
---

# API Content and Media Contract

## Goal

Bring the API guides into exact alignment with the new format-aware post writes, inline assets, galleries, header images, focal points, image contexts, and Prime capability discovery.

## Audit Findings

- The new endpoints are present, but nested media behavior is compressed into `posts.md` and lacks response examples and a clear feature-flag/error matrix.
- Post response examples do not say that `header_image`/`gallery_images` become `nil` when post images are disabled, while an enabled-but-unattached header image is `{ "attached": false }`.
- Focal/context requirements and `404` versus `422` behavior are not systematically documented.
- Upload inputs accept both top-level and nested parameter shapes in code, while docs show only one shape.
- Prime's example omits `posts.default_status` and the `taxonomies` capability returned by the controller.
- Supported Markdown extensions, HTML sanitization boundary, auto-detection limitations, and the fact that source format is discarded deserve one canonical explanation shared by JSON writes and imports.
- The changelog does not mention the newly added Post Assets, gallery images, or format-aware write features.

## Documentation Destinations

- Create `docs/api/post_media.md` for header/gallery/focal/context resources; retain `post_assets.md` for inline Action Text assets.
- Tighten `docs/api/posts.md`, `post_imports.md`, `prime.md`, `errors.md`, and API `README.md` with cross-links.
- Add discoverability links from README/CHANGELOG where appropriate.

## Plan

1. Define a content-format table for `html`, `markdown`, `plain`, `auto`, aliases, field-over-header precedence, HTML default, canonical HTML reads, and lossy source conversion.
2. Document the Redcarpet extensions actually enabled and distinguish API Markdown conversion from the admin editor's Markdown toggle.
3. Document the full inline-asset lifecycle, including unattached-blob cleanup responsibility and why `attachment_html` must be submitted as HTML.
4. Move nested media endpoint details into a dedicated guide with request and response samples for multipart and signed blobs, attachment ID versus blob ID, focal coordinates, crop bounds, upload overrides, and reset/delete behavior.
5. Add a feature matrix: inline assets always available when API is enabled; header/gallery require post images; focal/context endpoints require post images plus focal points; missing header image is `422`; disabled capability is `404`.
6. Synchronize Prime's documented JSON exactly with `PrimeController` and explain that returned paths are relative to the mounted engine.
7. Extend error docs with endpoint-specific validation examples without promising a global shape the controllers do not return.
8. Add Unreleased changelog entries and target-release upgrade notes for these additive API capabilities.

## Acceptance Criteria

- Every route under `api/v1` has an owning guide and is linked from `docs/api/README.md`.
- Example JSON matches serializer/controller keys and nullability.
- Each media endpoint lists its feature prerequisites and success/error statuses.
- Content format docs distinguish stored representation from submitted representation.
- Prime documentation is checked key-for-key against its controller/spec.

## Conventions

- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/testing/rspec/request_specs.md`

## Relevant System Documentation

- `config/routes.rb`
- `app/controllers/railspress/api/v1/`
- `app/models/railspress/post_content_formatter.rb`
- `docs/api/`
- `spec/requests/railspress/api/v1/`
