# Prime API (`v1`)

Endpoint: `GET /railspress/api/v1/prime`

Authentication: bearer token (see [authentication.md](authentication.md)).

Use this endpoint as the first connectivity handshake for agents and integrations.

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
        "list": true,
        "read": true,
        "create": true,
        "update": true,
        "delete": true,
        "rich_text_html": true,
        "content_formats": ["html", "markdown", "plain", "auto"],
        "read_content_format": "html",
        "publish_supported": true
      },
      "post_imports": {
        "create": true,
        "read": true,
        "formats": ["md", "markdown", "txt", "zip"]
      },
      "post_media": {
        "inline_images": true,
        "header_image": true,
        "gallery_images": true,
        "focal_points": true,
        "context_overrides": true
      }
    },
    "endpoints": {
      "prime": "/railspress/api/v1/prime",
      "posts": "/railspress/api/v1/posts",
      "post_imports": "/railspress/api/v1/posts/imports",
      "post_assets": "/railspress/api/v1/post_assets",
      "post_gallery_images": "/railspress/api/v1/posts/:post_id/gallery_images",
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

Media booleans reflect runtime configuration. Inline Action Text image uploads are available with the API; header images, galleries, focal points, and context overrides reflect their corresponding RailsPress feature flags.

## Draft vs publish

RailsPress post creation defaults to `draft` when `post[status]` is omitted.

To publish from an agent, explicitly send:

- `post[status] = "published"`
- optional: `post[published_at]`
