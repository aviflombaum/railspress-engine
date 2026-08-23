---
title: "Docs: configuration and feature dependency matrix"
type: docs
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Configuration options, dependencies, disabled behavior, and complete-migration semantics are documented."
priority: P1
---

# Configuration and Feature Dependency Matrix

## Goal

Add one accurate matrix showing what each feature toggle enables, its prerequisites, routes/models/helpers, and behavior when disabled.

## Audit Findings

- Individual options are documented, but cross-feature dependencies are hard to infer.
- `enable_focal_points` is described as requiring `enable_post_images`, while content-element/entity focal-point support has different code paths; the guide needs to distinguish Post UI/API gating from reusable focal-point model support.
- CMS routes are conditionally drawn, while API routes remain present and return `404` when API/features are disabled; this distinction is not summarized.
- Inline editing requires CMS plus a check proc, host JavaScript import, and `yield :head`, but these prerequisites are spread across guides.
- Agents & API requires encryption and a current-admin strategy for lifecycle auditing, while admin authentication protects a separate browser controller stack.
- `post_image_variants` also affects gallery attachments and forces WebP output, which is not consistently stated.

## Documentation Destinations

- Add the matrix near the start of `docs/CONFIGURING.md`.
- Link each row to `BLOGGING.md`, `ENTITIES.md`, `INLINE_EDITING.md`, focal point docs, or API docs.
- Add a compact “choose features” version to README only if it stays maintainable.

## Plan

1. Create columns for toggle, default, prerequisites, database/assets, admin UI, host helpers, API behavior, and disable behavior.
2. Separate core always-available blog models from opt-in UI/integration capabilities.
3. Clarify the three focal-point uses: Post header images, Entity focal-point attachments, and CMS image elements; verify which checks actually gate each surface before writing requirements.
4. Document validation timing and failures (`inline_editing_check` without CMS; API encryption at boot).
5. Add dependency recipes for blog only, blog+media, CMS+inline editing, entities+focal images, and Agents & API.
6. Expand programmatic accessor examples to cover relevant values such as image contexts, variants, public base URL, and inline editing check without treating internal registries as stable APIs.

## Acceptance Criteria

- Every `Configuration` reader/writer/toggle intended for hosts is documented once canonically.
- Prerequisites match runtime validation and controller/view gating.
- Disabled route/helper behavior is stated accurately.
- Browser admin authentication and bearer API authentication remain clearly separate.
- Variant behavior covers both header and gallery attachments.

## Conventions

- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/domain/route_naming.md`
- `docs/conventions/hotwire/stimulus_turbo_integration.md`

## Relevant System Documentation

- `lib/railspress.rb`
- `lib/railspress/engine.rb`
- `config/routes.rb`
- `app/controllers/railspress/admin/base_controller.rb`
- `app/controllers/railspress/api/v1/`
- `docs/CONFIGURING.md`
