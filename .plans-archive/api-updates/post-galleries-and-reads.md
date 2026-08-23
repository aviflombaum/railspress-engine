---
title: "feat: post gallery API and expanded JSON reads"
type: feat
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Gallery endpoints and expanded Post and Prime reads are implemented, tested, and documented."
---

# Post Gallery API and Expanded JSON Reads

## Goal

Add first-class gallery images to Posts through the API and make post read responses self-describing for content and media clients.

## Context

Posts currently support a header image, focal points, and context overrides when post images are enabled. They do not expose a gallery association. `GET /posts` and `GET /posts/:id` already return JSON and should include enough metadata to manage gallery images.

Relevant system docs:

- [Posts API](../../docs/api/posts.md)
- [Prime API](../../docs/api/prime.md)
- [Image focal point system](../../docs/image-focal-point-system.md)

## Scope Boundaries

In scope:

- `has_many_attached :gallery_images` on `Railspress::Post`
- Nested gallery index/create/destroy endpoints
- Multipart upload or signed blob ID attachment
- Gallery metadata in Post JSON reads
- Prime capability/endpoint discovery
- Request coverage and API documentation

Out of scope:

- Gallery ordering/reordering
- Captions, alt-text records, focal points, or per-image variants
- Admin gallery UI
- Adding gallery images inline during the initial Post create request

## Key Technical Decisions

1. Reuse the existing `post_images_enabled?` feature gate.
2. Scope deletion by both post ID and Active Storage attachment ID.
3. Return attachment IDs separately from blob IDs so clients can delete the correct gallery membership.
4. Keep gallery operations as nested resources instead of expanding already-complex Post write parameters.
5. Keep header images, inline content assets, and galleries as separate concepts.

## Plan

1. Add the gallery attachment association and eager loading for Post collection reads.
2. Add nested `gallery_images` index/create/destroy routes and controller.
3. Add gallery serialization to Post responses.
4. Advertise gallery support in Prime when post images are enabled.
5. Add request coverage for feature gating, upload, signed blob attachment, list, and scoped deletion.
6. Update Posts, Prime, and API overview documentation.

## Conventions

- `docs/conventions/data_layer/activerecord_patterns.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/integrations/external_apis.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
