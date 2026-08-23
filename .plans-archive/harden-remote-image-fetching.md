---
title: "fix: reject unsafe remote post images"
type: fix
created: 2026-08-18
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "SSRF filtering, dependency updates, regression coverage, and documentation are present."
---

# Reject Unsafe Remote Post Images

## Goal

Preserve remote header-image imports while preventing RailsPress from requesting loopback, private, link-local, reserved, or otherwise unsafe network addresses.

## Context

`Railspress::PostImportProcessor` currently passes a frontmatter URL directly to `URI.open`. Under RailsPress's trusted-admin model this is a Medium engine boundary issue rather than a Critical vulnerability: an administrator can already publish content, but an import should not inherit unrestricted access to the host application's private network or cloud metadata services.

A basic string denylist would stop obvious inputs such as `localhost` and `127.0.0.1`, but it would not cover IPv6, unusual IP representations, a public hostname resolving to a private address, connection-time DNS changes, or redirects. The implementation should remain small while delegating those security details to a focused, maintained library.

## Gem Research and Decision

Use [`ssrf_filter`](https://github.com/arkadiyt/ssrf_filter) `~> 1.5` as a direct runtime dependency.

Why it fits:

- Version `1.5.0` was released on April 3, 2026 and the repository remains active.
- It supports Ruby `>= 2.7`, which includes RailsPress's required Ruby `>= 3.3`.
- It has no runtime dependencies.
- It validates URI schemes, IPv4, IPv6, DNS results, translated address forms, and redirects.
- It connects to a selected validated public IP while retaining the hostname for HTTP and TLS, avoiding the validation/connection DNS gap that a standalone predicate would leave.
- Its `1.4.0` and `1.5.0` releases include recent denylist and redirect-header security fixes, so RailsPress should require the `1.5` line rather than allowing older releases.

Alternatives considered:

- Handwritten `URI`, `Resolv`, and `IPAddr` predicates would appear simple but would make RailsPress responsible for maintaining special-address ranges and safe connection pinning.
- [`faraday-restrict-ip-addresses`](https://rubygems.org/gems/faraday-restrict-ip-addresses) is useful for applications already using Faraday, but RailsPress does not use Faraday and would need an additional HTTP-client dependency.
- Rails itself and Active Storage do not provide a general SSRF-safe remote HTTP client.

No deprecation or sunset notice was found for `ssrf_filter`. RubyGems reports version `1.5.0`, MFA-protected publishing, and an MIT license.

## Scope Boundaries

### In scope

- Add `ssrf_filter ~> 1.5` to the engine runtime dependencies.
- Replace the remote-image `URI.open` request with `SsrfFilter.get`.
- Continue supporting both HTTP and HTTPS to avoid changing documented import behavior.
- Set `max_redirects: 0`; redirect responses are rejected rather than followed in this basic version.
- Attach a permitted response through `StringIO` using the response body and reported content type.
- Preserve the existing behavior in which a failed image fetch is logged and does not fail creation of the post itself.
- Add minimal public-behavior regression coverage for a private destination and a permitted remote-image response.
- Update import documentation and the security audit with the new behavior and residual risks.

### Out of scope

- Download byte-size limits, streaming, timeouts, or image-dimension limits.
- Image magic-byte validation, decoding, or re-encoding.
- Host allowlists or configuration to disable remote image fetching.
- Following redirects, even when the eventual target would be public.
- Network egress/firewall configuration in host applications.
- Refactoring all attachment logic into a generalized downloader abstraction.
- Version bumps, publishing, commits, or pushes.

## Key Technical Decisions

### 1. Use the safe client, not a preflight-only validator

Calling `SsrfFilter.get` is safer than validating with one method and then calling `URI.open` separately. The gem resolves the hostname, rejects unsafe address ranges, and connects to the validated address. This prevents the normal time-of-check/time-of-use gap between DNS validation and the HTTP connection.

### 2. Reject redirects in the first iteration

Pass `max_redirects: 0`. A redirect raises `SsrfFilter::TooManyRedirects`, which is handled like the existing remote-image download errors. This keeps the behavior easy to reason about and removes redirect chains from the initial scope. If legitimate imports require redirects later, `ssrf_filter` can follow them while revalidating each destination.

### 3. Keep the change inside the existing processor

`PostImportProcessor` already owns URL detection, fetching, filename selection, attachment, and per-image failure handling. For one call site, adding a separate application service would create indirection without providing a second consumer or policy. Extraction can be reconsidered if other RailsPress features begin fetching untrusted URLs.

### 4. Do not claim that Rails limits the response size

Active Storage records a blob's byte size but does not impose an engine-level maximum here. Size and content validation remain documented residual hardening items rather than being implied by this SSRF fix.

## Implementation Plan

### Unit 1: Replace the unsafe HTTP client

Files:

- `railspress.gemspec`
- `Gemfile.lock`
- `app/models/railspress/post_import_processor.rb`

Work:

1. Add `ssrf_filter`, constrained to the current `1.5` minor line, as a runtime dependency.
2. Require `ssrf_filter` and `stringio`; remove `open-uri` if it has no remaining use.
3. In `attach_image_from_url`, retain the existing URL parsing and filename derivation.
4. Fetch with `SsrfFilter.get(url, max_redirects: 0)`.
5. Attach `StringIO.new(response.body)` and use `response.content_type` as the attachment metadata.
6. Handle `SsrfFilter::Error` alongside URI/network failures through the existing logged, non-fatal image-attachment boundary.
7. Do not duplicate the gem's private-address tables or DNS logic in RailsPress.

### Unit 2: Add minimal behavioral coverage

File:

- `spec/models/railspress/post_import_processor_spec.rb`

Work:

1. Add a post-import example whose remote image points to a loopback address and assert the post is created without an attached header image. The gem rejects the literal before any connection is made.
2. Add a permitted-response example using a verifying/partial double for `SsrfFilter.get`; return a small real fixture image and assert it is attached.
3. Verify the safe client is invoked with `max_redirects: 0`, establishing that RailsPress does not follow redirects in this version.
4. Remove or replace the current private-method `url?` example if the new public-behavior examples make it redundant.
5. Do not add WebMock, VCR, or another testing dependency for these deterministic cases.

### Unit 3: Document the contract

Files:

- `docs/IMPORT_EXPORT.md`
- `tmp/security-audit-8-18-26.md`

Work:

1. Document that remote image URLs support HTTP/HTTPS public destinations only.
2. Document that redirects are rejected in the basic implementation.
3. Mark RP-03 as remediated for the core private-network SSRF path.
4. Keep unbounded response size and unverified image content recorded as separate residual hardening work rather than declaring the entire remote-import surface risk-free.

## Minimal Test Strategy

- One rejected loopback import proving that unsafe destinations are not requested or attached.
- One permitted response proving that normal remote image attachment still works.
- One assertion on `max_redirects: 0` folded into the permitted-response behavior rather than a separate implementation-detail example.
- Existing post-import and ZIP-image specs remain the happy-path regression suite.

## Verification

1. Capture an `agent-rspec` baseline before source changes.
2. Run `spec/models/railspress/post_import_processor_spec.rb` through `bin/agent-rspec` with fail-fast behavior.
3. Run RuboCop on the touched Ruby/spec files.
4. Run `bundler-audit check --update` after resolving the new dependency.
5. Run the full `agent-rspec` post suite and compare it with the baseline.

## Acceptance Criteria

- RailsPress no longer uses `URI.open` for imported remote images.
- Literal and DNS-resolved unsafe destinations are rejected by the request client.
- RailsPress does not follow remote-image redirects.
- A permitted HTTP/HTTPS image response can still be attached.
- Unsafe or failed remote images do not prevent the post itself from importing.
- The new dependency is limited to `ssrf_filter ~> 1.5` and adds no transitive runtime dependencies.
- Focused specs, RuboCop, Bundler Audit, and post-work suite comparison pass without new failures.

## Residual Risk

This basic version addresses the core SSRF boundary substantially better than string validation alone. It intentionally does not bound response bytes or verify that the response body is a decodable image. Those concerns remain availability and content-hardening work. Host-level outbound network controls remain useful defense in depth.

## Open Questions

None. The plan preserves current HTTP/HTTPS support and chooses fail-closed redirect behavior for the initial implementation.

## Conventions

- `docs/conventions/architecture/coding_patterns.md`
- `docs/conventions/architecture/rescue_and_logging.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/model_specs.md`
- `docs/conventions/testing/rspec/isolation.md`

## Relevant System Documentation

- `docs/IMPORT_EXPORT.md`
- `tmp/security-audit-8-18-26.md`

## Research Sources

- `ssrf_filter` repository and API: <https://github.com/arkadiyt/ssrf_filter>
- `ssrf_filter` releases: <https://github.com/arkadiyt/ssrf_filter/blob/main/CHANGELOG.md>
- `ssrf_filter` package metadata: <https://rubygems.org/gems/ssrf_filter>
- OWASP SSRF Prevention Cheat Sheet: <https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html>
- Faraday middleware alternative: <https://rubygems.org/gems/faraday-restrict-ip-addresses>
