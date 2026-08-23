---
title: "Test Fixes from Harden Remote Image Fetching"
status: implemented
priority: p3
created: 2026-08-18
created_by: Avi Flombaum
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "The original seed 10117 now passes 870 examples with no failures; fixture-order regressions are resolved."
tags: [test-fixes, flaky]
---

# Test Fixes from Harden Remote Image Fetching

## Context

- **Branch:** `chore/security-audit-1-4-4`
- **Commit:** `22092f7`
- **Plan:** `plans/harden-remote-image-fetching.md`
- **Baseline:** `tmp/rspec/2026-08-18-harden-remote-image-fetching-baseline.json`
- **Post:** `tmp/rspec/2026-08-18-harden-remote-image-fetching-post.json`
- **Diff:** `tmp/rspec/2026-08-18-harden-remote-image-fetching-diff.json`

## Pre-Existing Failures

None in the captured baseline: 786 examples, 0 failures, 1 pending.

## Unrelated Regressions

The final randomized post run produced 13 fixture-setup failures. The same suite passed in the baseline and in an earlier post run during this work, confirming order-dependent fixture leakage. Every failure occurs before the example body with:

```text
Foreign key violations found: railspress_posts, railspress_posts,
railspress_posts, railspress_posts
```

Affected examples:

- `spec/models/railspress/api_key_spec.rb`
  - `.issue! creates an api key with owner and created_by metadata`
  - `.issue! stores encrypted secret material`
  - `.authenticate returns the matching active key for a valid token`
  - `.authenticate returns nil for revoked keys`
  - `.authenticate returns nil for expired keys`
  - `#rotate! creates a replacement key and revokes the original key`
  - `#revoke! marks key as revoked with actor metadata`
- `spec/requests/railspress/api/v1/tags_spec.rb`
  - `GET /api/v1/tags returns tags with pagination metadata`
  - `GET /api/v1/tags/:id returns a single tag`
  - `POST /api/v1/tags creates a tag with valid params`
  - `POST /api/v1/tags returns validation errors for invalid params`
  - `PATCH /api/v1/tags/:id updates the tag`
  - `DELETE /api/v1/tags/:id deletes the tag`

## Suggested Investigation

1. Reproduce with seed `10117`.
2. Identify the earlier example group that changes fixture configuration or deletes association records without restoring them.
3. Ensure fixture declarations load referenced author/category records before `railspress/posts`.
4. Remove global configuration leakage between example groups rather than adding table cleanup.
5. Verify the full suite under several randomized seeds.

## Relation to Current Work

The remote-image implementation does not touch API keys, tags, fixture declarations, or fixture setup. Its focused model suite passes 35 examples with no failures.
