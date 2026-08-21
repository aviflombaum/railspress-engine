---
title: "Test Fixes from API Encryption Setup 1.4.5"
status: implemented
priority: p3
created: 2026-08-21
created_by: Avi Flombaum
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Stimulus is served locally, external font requests are removed, regression specs are present, and the full suite passes."
tags: [test-fixes, flaky]
---

# Test Fixes from API Encryption Setup 1.4.5

## Context

- **Branch:** `fix/api-encryption-setup-1-4-5`
- **Commit:** `3c91306`
- **Plan:** API encryption setup and documentation work
- **Baseline:** `tmp/rspec/2026-08-21-api-encryption-setup-1-4-5-baseline.json`
- **Post:** `tmp/rspec/2026-08-21-api-encryption-setup-1-4-5-post.json`
- **Diff:** `tmp/rspec/2026-08-21-api-encryption-setup-1-4-5-diff.json`

## Pre-Existing Failures

- `spec/system/railspress/admin/view_styling_spec.rb` intermittently times out waiting for external JSPM and Google Fonts resources. Six examples failed in the baseline and three failed in the post run, with the specific examples varying between runs.

## Unrelated Regressions

- Two post-run examples were categorized as new only because different examples encountered the same pre-existing `Ferrum::PendingConnectionsError`. Prevent external asset requests from controlling system-spec completion, or serve/stub those assets locally for deterministic browser tests.
