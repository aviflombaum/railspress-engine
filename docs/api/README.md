# RailsPress API

RailsPress exposes a versioned JSON API for programmatic CRUD operations on RailsPress content.

Current version: `v1`
Base path (default mount): `/railspress/api/v1`

## Guides

- [Authentication](authentication.md)
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

2. Create an API key in RailsPress admin:
- Go to `/railspress/admin/api_keys`
- Create a key and copy the one-time token reveal

3. Call the API with bearer auth:

```bash
curl -H "Authorization: Bearer rp_test_..." \
  http://localhost:3000/railspress/api/v1/posts
```

## v1 Scope

- API keys are full-access for currently exposed v1 resources.
- Key lifecycle management is admin-only in v1.
