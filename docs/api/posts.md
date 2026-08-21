# Posts API (`v1`)

Base path: `/railspress/api/v1/posts`

Authentication: bearer token (see [authentication.md](authentication.md)).

For markdown/text/zip attachment imports, use [post_imports.md](post_imports.md).

## Response Shape

Single resource:

```json
{
  "data": {
    "id": 123,
    "title": "Hello World",
    "slug": "hello-world",
    "status": "draft",
    "published_at": null,
    "reading_time": 3,
    "meta_title": null,
    "meta_description": null,
    "category_id": null,
    "author_id": 7,
    "author_display": "avi@example.com",
    "tag_list": "rails, api",
    "content": "<h2>Intro</h2><div>...</div>",
    "content_format": "html",
    "header_image": {
      "attached": true,
      "blob_id": 45,
      "signed_blob_id": "eyJfcmFpbHMiOns...",
      "filename": "hero.png",
      "byte_size": 214523,
      "content_type": "image/png"
    },
    "gallery_images": [
      {
        "id": 91,
        "blob_id": 46,
        "signed_blob_id": "eyJfcmFpbHMiOns...",
        "filename": "gallery-one.png",
        "byte_size": 104857,
        "content_type": "image/png"
      }
    ],
    "header_image_focal_point": {
      "id": 17,
      "attachment_name": "header_image",
      "focal_x": 0.5,
      "focal_y": 0.5,
      "overrides": {}
    },
    "created_at": "2026-04-15T10:00:00.000Z",
    "updated_at": "2026-04-15T10:00:00.000Z"
  }
}
```

Collection response includes `meta`:

```json
{
  "data": [ ... ],
  "meta": {
    "page": 1,
    "per": 20,
    "total_count": 42,
    "total_pages": 3
  }
}
```

## Content Formats

`post[content]` accepts HTML, Markdown, or plain text. Set the format with `post[content_format]`:

- `html`: stores HTML through Action Text sanitization
- `markdown`: renders Markdown to rich HTML before Action Text assignment
- `plain`: escapes HTML and preserves paragraphs/newlines without interpreting Markdown
- `auto`: detects obvious HTML or Markdown and otherwise uses plain text

The JSON field takes precedence over the `X-Railspress-Content-Format` request header. The header accepts the same names plus `text/html`, `text/markdown`, and `text/plain` MIME aliases.

For backward compatibility, an omitted format means `html`. Auto detection only occurs when `auto` is explicitly requested.

Markdown example:

```json
{
  "post": {
    "title": "API Markdown Post",
    "content": "## Section\n\nHello **world**.",
    "content_format": "markdown"
  }
}
```

All read responses return canonical Action Text HTML and report `content_format: "html"`. The original Markdown/plain source is not persisted and therefore cannot be losslessly returned.

For inline images, upload through [Post Assets](post_assets.md), insert the returned `attachment_html` into an HTML body, and submit that body with `content_format: "html"`.

## Endpoints

### `GET /posts`

Query params:

- `page` (default `1`)
- `per` (default `20`, max `100`)
- `sort` (default `created_at`)
- `direction` (`asc` or `desc`, default `desc`)

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/posts?page=1&per=10"
```

### `GET /posts/:id`

v1 lookup is numeric ID only.

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/posts/123"
```

### `POST /posts`

Required:

- `post[title]`

Default behavior:

- If `post[status]` is omitted, the post is created as `draft`.
- To publish, explicitly set `post[status]` to `published`.

Optional:

- `post[slug]`
- `post[category_id]`
- `post[content]`
- `post[content_format]` (`html`, `markdown`, `plain`, or `auto`; default `html`)
- `post[status]` (`draft` or `published`)
- `post[published_at]`
- `post[reading_time]`
- `post[meta_title]`
- `post[meta_description]`
- `post[tag_list]`
- `post[author_id]` (only when authors are enabled)
- `post[header_image]` (multipart upload, only when post images are enabled)
- `post[header_image_signed_blob_id]` (direct-upload flow, only when post images are enabled)
- `post[remove_header_image]` (`"1"` to remove attached header image)
- `post[header_image_focal_point_attributes][focal_x]` (0..1)
- `post[header_image_focal_point_attributes][focal_y]` (0..1)
- `post[header_image_focal_point_attributes][overrides]` (JSON object)

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "API-created post",
      "status": "draft",
      "tag_list": "rails,api",
      "content": "## Hello API\n\nCreated from JSON.",
      "content_format": "markdown"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/posts"
```

### `PATCH /posts/:id`

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "post": {
      "title": "Updated title",
      "meta_description": "Updated via API"
    }
  }' \
  "http://localhost:3000/railspress/api/v1/posts/123"
```

### `DELETE /posts/:id`

Returns `204 No Content` on success.

```bash
curl -X DELETE \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/posts/123"
```

## Nested Header Image Resources

### `GET /posts/:post_id/header_image`

Returns metadata for the post header image (and focal point data when enabled).

### `PUT /posts/:post_id/header_image`

Attach or replace header image via:

- `signed_blob_id` (JSON body) for Active Storage direct-upload blobs
- `image` (multipart file upload)

```bash
curl -X PUT \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "signed_blob_id": "eyJfcmFpbHMiOns..."
  }' \
  "http://localhost:3000/railspress/api/v1/posts/123/header_image"
```

### `DELETE /posts/:post_id/header_image`

Purges the current header image.

## Nested Gallery Image Resources

Gallery resources are available only when `config.enable_post_images` is set. Gallery images do not have header-image focal points or context overrides.

### `GET /posts/:post_id/gallery_images`

Returns gallery attachment metadata. The attachment `id` is the resource ID used for deletion; it is distinct from `blob_id`.

### `POST /posts/:post_id/gallery_images`

Attach an image with multipart form data:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "image=@./gallery-one.png" \
  "http://localhost:3000/railspress/api/v1/posts/123/gallery_images"
```

Or attach an existing Active Storage blob:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"signed_blob_id":"eyJfcmFpbHMiOns..."}' \
  "http://localhost:3000/railspress/api/v1/posts/123/gallery_images"
```

Supported types are JPEG, PNG, GIF, and WebP.

### `DELETE /posts/:post_id/gallery_images/:id`

Purges one gallery attachment and returns `204 No Content`.

## Nested Focal Point Resource

### `GET /posts/:post_id/header_image/focal_point`

Returns focal point data for the header image.

### `PATCH /posts/:post_id/header_image/focal_point`

Update focal point and optional context overrides.

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "focal_point": {
      "focal_x": 0.2,
      "focal_y": 0.7,
      "overrides": {
        "hero": { "type": "focal" }
      }
    }
  }' \
  "http://localhost:3000/railspress/api/v1/posts/123/header_image/focal_point"
```

## Nested Header Image Context Resources

These endpoints manage per-context overrides (`focal`, `crop`, `upload`) used by RailsPress image contexts (for example `hero`, `card`, `thumb`).

### `GET /posts/:post_id/header_image/contexts`

Returns all configured contexts and current override/effective image metadata.

### `GET /posts/:post_id/header_image/contexts/:context`

Returns a single context override state.

### `PATCH /posts/:post_id/header_image/contexts/:context`

Set context override type:

- `override[type] = "focal"` to use global focal point
- `override[type] = "crop"` + `override[region]` with normalized `x/y/width/height`
- `override[type] = "upload"` + `override[signed_blob_id]`

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "override": {
      "type": "crop",
      "region": {
        "x": 0.1,
        "y": 0.2,
        "width": 0.6,
        "height": 0.5
      }
    }
  }' \
  "http://localhost:3000/railspress/api/v1/posts/123/header_image/contexts/hero"
```

### `DELETE /posts/:post_id/header_image/contexts/:context`

Clears custom override and reverts the context to `focal` behavior.
