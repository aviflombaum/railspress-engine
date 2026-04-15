# Prime API (`v1`)

Endpoint: `GET /railspress/api/v1/prime`

Authentication: bearer token (see [authentication.md](authentication.md)).

Use this endpoint as a connectivity handshake for agents and integrations.

It returns:

- API identity/version
- auth model
- defaults (`draft` post creation by default)
- available capabilities
- useful endpoint paths
- current API key metadata

## Example

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/prime"
```

## Response shape

```json
{
  "data": {
    "service": "Railspress API",
    "version": "v1",
    "authentication": {
      "type": "bearer",
      "token_types": ["api_key", "agent_bootstrap_key"],
      "agent_bootstrap_exchange_endpoint": "/railspress/api/v1/agent_keys/exchange"
    },
    "defaults": {
      "post_status": "draft",
      "publish_with_explicit_status": true
    },
    "capabilities": {
      "posts": {
        "create": true,
        "update": true,
        "publish_supported": true
      }
    },
    "endpoints": {
      "prime": "/railspress/api/v1/prime",
      "posts": "/railspress/api/v1/posts",
      "post_imports": "/railspress/api/v1/posts/imports",
      "categories": "/railspress/api/v1/categories",
      "tags": "/railspress/api/v1/tags"
    },
    "key": {
      "id": 1,
      "name": "Agent Key",
      "status": "active"
    },
    "server_time": "2026-04-16T00:00:00.000Z"
  }
}
```

## Draft vs publish

RailsPress post creation defaults to `draft` when `post[status]` is omitted.

To publish from an agent, explicitly send:

- `post[status] = "published"`
- optional: `post[published_at]`
