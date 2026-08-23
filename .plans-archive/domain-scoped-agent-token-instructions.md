---
title: "fix: host-scoped agent token storage instructions"
type: fix
created: 2026-08-21
created_by: Avi Flombaum
status: implemented
implemented: 2026-08-21
last_reviewed_at: 2026-08-21
last_reviewed_by: Avi Flombaum
sweep_confidence: 100%
sweep_notes: "Host/port/path-scoped token files, safe shell instructions, documentation, and request specs are present."
---

# Host-Scoped Agent Token Storage Instructions

## Goal

Update generated RailsPress API and bootstrap instructions so each host application writes its long-lived API token to a distinct local file instead of sharing `~/.railspress_token`.

For the request URL `http://127.0.0.1:3129`, the generated path should be recognizable and collision-resistant, for example:

```text
~/.railspress/tokens/127.0.0.1-3129
```

## Context

The admin-generated snippets are copied into agent setup flows. Today every RailsPress application writes to `~/.railspress_token`, so configuring a second application silently replaces the first application's credential.

RailsPress already resolves an instruction base URL in `Admin::BaseController`, in this order:

1. `config.public_base_url`
2. `Rails.application.routes.default_url_options`
3. the current request base URL

That resolved URL is a better credential identifier than the Rails application class name or a human-facing site name:

- It identifies the API endpoint where the credential is valid.
- Hostnames naturally distinguish production sites.
- Including a non-default port distinguishes local applications such as `127.0.0.1:3129` and `127.0.0.1:3130`.
- Including a configured base path avoids collisions when multiple applications are served beneath one host.
- It requires no new host-app configuration.

`Rails.application.class.module_parent_name` is not the default because the same application code can be deployed as multiple sites, and generated application names such as `Dummy` are not necessarily meaningful to users.

Relevant system docs:

- `docs/api/authentication.md`
- `docs/api/agent_bootstrap_keys.md`
- `docs/CONFIGURING.md` (`public_base_url`)

## Scope Boundaries

In scope:

- Generated direct API-key instructions and quick start
- Generated generic agent/bootstrap instructions
- Generated one-time bootstrap reveal instructions and quick start
- API-key reveal hint that currently names `~/.railspress_token`
- Documentation for optional local token storage
- Request specs covering production-style hosts, local ports, and configured base URLs

Out of scope:

- API token format or authentication behavior
- Database schema or persisted key records
- Renaming `RAILSPRESS_TOKEN`; it remains the active shell variable for a single command/session
- Automatic migration or deletion of an existing `~/.railspress_token`
- Adding a site-name configuration setting solely for credential filenames

## Key Technical Decisions

### Derive a storage scope from the resolved instruction URL

Parse `instruction_base_url` and build a filesystem-safe scope from:

- lowercase host
- non-default port, when present
- normalized base path, when present

Preserve dots for readable hostnames and replace other unsafe runs with `-`. Reject or fall back safely if parsing does not yield a host. Example mappings:

| Instruction base URL | Token scope |
|---|---|
| `https://blog.example.com` | `blog.example.com` |
| `http://127.0.0.1:3129` | `127.0.0.1-3129` |
| `https://example.com/publishing` | `example.com-publishing` |

Do not reduce a hostname to its registrable domain: `blog.example.com` and `docs.example.com` may be separate RailsPress applications with different credentials.

### Store tokens under one private RailsPress directory

Generate a token file variable and use it consistently:

```bash
export RAILSPRESS_TOKEN_FILE="$HOME/.railspress/tokens/127.0.0.1-3129"
install -d -m 700 "$(dirname "$RAILSPRESS_TOKEN_FILE")"
printf '%s\n' "$RAILSPRESS_TOKEN" > "$RAILSPRESS_TOKEN_FILE"
chmod 600 "$RAILSPRESS_TOKEN_FILE"
export RAILSPRESS_TOKEN="$(cat "$RAILSPRESS_TOKEN_FILE")"
```

The directory keeps the home directory uncluttered, while the explicit variable makes later commands readable. Keep `RAILSPRESS_BOOTSTRAP_TOKEN` transient and generic because it is short-lived and exchange-only.

### Keep derivation shared

Put URL parsing and token-path generation in `Railspress::Admin::BaseController`, beside `instruction_base_url`, so both API-key controllers use exactly the same rule. Do not duplicate the transformation in instruction-building methods.

## Plan

1. Add private helpers to `Railspress::Admin::BaseController` that derive a safe token scope and shell token-file path from `instruction_base_url`.
2. Update `Admin::ApiKeysController` direct-key, generic bootstrap, and quick-start copy to create, write, read, and reference the scoped token file.
3. Update `Admin::AgentBootstrapKeysController` reveal and quick-start copy to use the same scoped path.
4. Update the API-key reveal hint so it no longer recommends the global `~/.railspress_token` file.
5. Update the optional-storage example in `docs/api/authentication.md` and explain that generated admin instructions derive the filename from the configured public URL or request host.
6. Extend request specs to verify:
   - `http://127.0.0.1:3129` generates `127.0.0.1-3129`
   - a normal HTTPS host generates a readable host scope without `-443`
   - different subdomains remain distinct
   - `config.public_base_url` controls both instruction URLs and token scope
   - generated snippets no longer write `~/.railspress_token`
7. Run the focused admin request specs with `--fail-fast`.

## Open Questions

None for the initial change. If users later need a friendly alias that differs from the endpoint, add an explicit setting such as `config.agent_token_scope`; do not overload a broad `site_name` setting for a credential-storage concern.

## Conventions

- `docs/conventions/domain/authentication.md`
- `docs/conventions/frontend/admin_ui_patterns.md`
- `docs/conventions/frontend/layouts_and_views.md`
- `docs/conventions/operations/initializers_and_config.md`
- `docs/conventions/testing/rspec/overview.md`
- `docs/conventions/testing/rspec/request_specs.md`
