---
title: "feat: authenticated inline content asset API"
type: feat
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Authenticated inline asset endpoints, signed metadata, tests, and API documentation are present."
---

# Authenticated Inline Content Asset API

## Goal

Give API clients a supported way to upload an image before creating or updating a post and receive canonical Action Text attachment markup for insertion into post content.

## Context

Action Text can resolve Active Storage blobs embedded as `<action-text-attachment>` elements, but the API currently expects clients to manufacture that markup without providing an API-key-authenticated upload endpoint.

Relevant system docs:

- [Posts API](../../docs/api/posts.md)
- [Authentication](../../docs/api/authentication.md)

## Scope Boundaries

In scope:

- `POST /api/v1/post_assets`
- Multipart image upload or an existing Active Storage signed blob ID
- JPEG, PNG, GIF, and WebP validation
- Blob metadata, signed blob ID, attachable SGID, and canonical attachment HTML response
- Prime capability/endpoint discovery
- Request specs and API documentation

Out of scope:

- Non-image files
- Remote URL downloads
- Automatic mutation of a post body
- Asset ownership/scopes beyond the v1 full-access API-key model
- A permanent standalone media-library record

## Key Technical Decisions

1. Keep uploads independent of posts so clients can construct content before post creation.
2. Return Action Text-generated markup rather than asking clients to reproduce its private SGID format.
3. Accept only the image types already supported by imports.
4. Use the host application's Active Storage service and existing API bearer authentication.
5. Document unattached-blob cleanup as an operational concern shared with normal Active Storage direct uploads.

## Plan

1. Add a RESTful create-only `post_assets` API resource.
2. Create/upload or resolve the blob and validate its content type.
3. Serialize stable blob metadata and `ActionText::Attachment.from_attachable(blob).to_html`.
4. Advertise the capability and endpoint through Prime.
5. Add authenticated success and validation request coverage.
6. Document the upload-then-embed workflow with examples.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
