# Categories API (`v1`)

Base path: `/railspress/api/v1/categories`

Authentication: bearer token (see [authentication.md](authentication.md)).

## Endpoints

### `GET /categories`

Query params:
- `page` (default `1`)
- `per` (default `20`, max `100`)

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/categories?page=1&per=20"
```

### `GET /categories/:id`

Numeric ID lookup only.

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/categories/1"
```

### `POST /categories`

Required:
- `category[name]`

Optional:
- `category[slug]`
- `category[description]`

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": {
      "name": "Engineering",
      "description": "Engineering posts"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/categories"
```

### `PATCH /categories/:id`

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": {
      "name": "Platform"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/categories/1"
```

### `DELETE /categories/:id`

Returns:
- `204 No Content` on success
- `422 Unprocessable Content` if category still has posts

```bash
curl -X DELETE \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/categories/1"
```
