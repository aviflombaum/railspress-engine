# Tags API (`v1`)

Base path: `/railspress/api/v1/tags`

Authentication: bearer token (see [authentication.md](authentication.md)).

## Endpoints

### `GET /tags`

Query params:
- `page` (default `1`)
- `per` (default `20`, max `100`)

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/tags?page=1&per=20"
```

### `GET /tags/:id`

Numeric ID lookup only.

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/tags/1"
```

### `POST /tags`

Required:
- `tag[name]`

Optional:
- `tag[slug]`

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tag": {
      "name": "security"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/tags"
```

### `PATCH /tags/:id`

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tag": {
      "name": "ruby-on-rails"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/tags/1"
```

### `DELETE /tags/:id`

Returns `204 No Content` on success.

```bash
curl -X DELETE \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/tags/1"
```
