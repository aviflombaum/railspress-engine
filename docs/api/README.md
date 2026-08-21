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

2. Open **Agents & API** in admin (`/railspress/admin/api_keys`) and create a bootstrap key:
- Go to `/railspress/admin/api_keys`
- Click **New Agent Key** and copy the one-time reveal instructions
- Exchange the bootstrap token once to mint an API key

3. Call the API with the API key bearer token:

```bash
curl -H "Authorization: Bearer rp_test_..." \
  http://localhost:3000/railspress/api/v1/prime
```

## v1 Scope

- API keys are full-access for currently exposed v1 resources.
- Key lifecycle management is admin-only in v1.
- Bootstrap keys are onboarding-only and cannot access content endpoints directly.
- Token plaintext is shown once at create/rotate/exchange time.
- Post reads are JSON and return canonical Action Text HTML.
- Post writes accept HTML, Markdown, or plain text with an explicit content format.
- Inline content images use the Post Assets endpoint; header images and gallery images have separate Post resources.
