# RailsPress API

RailsPress exposes a versioned JSON API for programmatic CRUD operations on RailsPress content.

Current version: `v1`
Base path (default mount): `/railspress/api/v1`

## Guides

- [Authentication](authentication.md)
- [Agent Bootstrap Keys](agent_bootstrap_keys.md)
- [Prime](prime.md)
- [Errors](errors.md)
- [Posts](posts.md)
- [Post Assets](post_assets.md)
- [Post Media](post_media.md)
- [Post Imports](post_imports.md)
- [Categories](categories.md)
- [Tags](tags.md)

## Quickstart

1. Enable API in your initializer:

```ruby
Railspress.configure do |config|
  config.enable_api
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
  # Optional canonical host used in generated instruction snippets:
  # config.public_base_url = "https://blog.example.com"
end
```

2. Open **Agents & API** in admin (`/railspress/admin/api_keys`). Install
RailsPress Agent, which includes the CLI and skills for detected Codex/Claude
runtimes:

```bash
curl -fsSL https://agent.railspress.org/install.sh | sh
```

The installer checks requirements automatically. An inspect-first installation
is available under the advanced installation guidance.

Save the generated token-free project connection file as `RAILSPRESS.md` in
the root of the project whose content the agent will publish. It selects this
RailsPress host/API/token path without containing credentials.

3. Create an **Agent Setup Key** and run its generated connection command:

```bash
export RAILSPRESS_BOOTSTRAP_TOKEN="rpb_test_..."
printf '%s\n' "$RAILSPRESS_BOOTSTRAP_TOKEN" \
  | railspress-agent connect --start /path/to/project --json
```

`connect` displays the normalized connection for explicit local approval,
exchanges the setup key once, stores only the API key, and verifies `/prime`.
It never replaces changed trust or an existing credential. The lower-level
`config` and `onboard` commands remain available for automation and diagnosis.

4. For returning sessions, verify the server contract before every write:

```bash
"$HOME/.railspress/bin/railspress-agent" prime --start /path/to/project --json
```

Create a reusable **Developer API Key** for custom scripts, CI, or clients that
intentionally do not use Agent Setup Keys. Direct bearer-token HTTP and the
manual/no-CLI agent protocol remain available under [Authentication](authentication.md)
and [Agent Bootstrap Keys](agent_bootstrap_keys.md).

## v1 Scope

- API keys are full-access for currently exposed v1 resources.
- Key lifecycle management is admin-only in v1.
- Bootstrap keys are onboarding-only and cannot access content endpoints directly.
- Token plaintext is shown once at create/rotate/exchange time.
- Post reads are JSON and return canonical Action Text HTML.
- Post writes accept HTML, Markdown, or plain text with an explicit content format.
- Inline content images use the Post Assets endpoint; header images and gallery images have separate Post resources.
