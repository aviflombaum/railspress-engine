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
- [Post Imports](post_imports.md)
- [Categories](categories.md)
- [Tags](tags.md)

## Quickstart

1. Enable API in your initializer:

```ruby
Railspress.configure do |config|
  config.enable_api
  config.current_api_actor_method = :current_user
end
```

2. Create a bootstrap key in RailsPress admin (`/railspress/admin/api_keys`):
- Go to `/railspress/admin/api_keys`
- Create an **Agent Bootstrap Key** and copy the one-time reveal instructions
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
