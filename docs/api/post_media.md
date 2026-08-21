# Post Media API (`v1`)

Post media consists of three distinct surfaces:

| Surface | Purpose | Feature requirement |
|---------|---------|---------------------|
| [Post Assets](post_assets.md) | Inline Action Text images embedded in `post[content]` | Agents & API enabled |
| Header image and gallery images | Post-level presentation media | `config.enable_post_images` |
| Header focal point and contexts | Global focus plus per-context crop/upload overrides | Post images and `config.enable_focal_points` |

Authentication is a RailsPress API bearer token for every endpoint.

## Feature and Error Behavior

- A disabled post-image or focal-point capability returns `404 Not Found`.
- A missing Post or gallery attachment returns `404 Not Found`.
- Focal/context operations with no attached header image return `422 Unprocessable Content`.
- Missing upload parameters, invalid signed blob IDs, and invalid crop regions return `422 Unprocessable Content`.
- Inline-asset and gallery upload endpoints validate JPEG, PNG, GIF, and WebP content types. The header-image endpoint currently delegates attachment validation to Active Storage/the host and does not apply that API allowlist.

## Header Image

Base path: `/railspress/api/v1/posts/:post_id/header_image`

### Read

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "$BASE_URL/railspress/api/v1/posts/123/header_image"
```

An attached image returns:

```json
{
  "data": {
    "post_id": 123,
    "header_image": {
      "attached": true,
      "blob_id": 45,
      "signed_blob_id": "eyJfcmFpbHMiOns...",
      "filename": "hero.png",
      "byte_size": 214523,
      "content_type": "image/png"
    },
    "header_image_focal_point": null
  }
}
```

The focal-point value is populated only when focal points are enabled.

### Attach or replace

`PUT` or `PATCH` accepts a top-level multipart `image` or JSON `signed_blob_id`:

```bash
curl -X PUT \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "image=@./hero.png" \
  "$BASE_URL/railspress/api/v1/posts/123/header_image"
```

```bash
curl -X PUT \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"signed_blob_id":"eyJfcmFpbHMiOns..."}' \
  "$BASE_URL/railspress/api/v1/posts/123/header_image"
```

The response is the complete serialized Post.

### Remove

```bash
curl -X DELETE \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "$BASE_URL/railspress/api/v1/posts/123/header_image"
```

Removal purges the attachment and returns `204 No Content`.

## Gallery Images

Base path: `/railspress/api/v1/posts/:post_id/gallery_images`

### List

`GET` returns attachment metadata in attachment order:

```json
{
  "data": [
    {
      "id": 91,
      "blob_id": 46,
      "signed_blob_id": "eyJfcmFpbHMiOns...",
      "filename": "gallery-one.png",
      "byte_size": 104857,
      "content_type": "image/png"
    }
  ]
}
```

`id` is the Active Storage attachment resource ID used for deletion. It is not the blob ID.

### Attach

The endpoint accepts either top-level `image`/`signed_blob_id` or the same values nested under `gallery_image`:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "image=@./gallery-one.png" \
  "$BASE_URL/railspress/api/v1/posts/123/gallery_images"
```

```json
{
  "gallery_image": {
    "signed_blob_id": "eyJfcmFpbHMiOns..."
  }
}
```

Successful attachment returns the new attachment metadata with `201 Created`.

### Remove one gallery image

```bash
curl -X DELETE \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "$BASE_URL/railspress/api/v1/posts/123/gallery_images/91"
```

This purges the attachment and returns `204 No Content`.

## Header Image Focal Point

Base path: `/railspress/api/v1/posts/:post_id/header_image/focal_point`

`GET` returns focal coordinates normalized to `0..1` and the stored context override object. If the attachment does not yet have a focal-point row, RailsPress creates the centered default (`0.5`, `0.5`).

Update with `PUT` or `PATCH`:

```bash
curl -X PATCH \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "focal_point": {
      "focal_x": 0.2,
      "focal_y": 0.7,
      "overrides": {}
    }
  }' \
  "$BASE_URL/railspress/api/v1/posts/123/header_image/focal_point"
```

The response contains the focal point as `data` and the refreshed Post as `post`.

## Header Image Contexts

Base path: `/railspress/api/v1/posts/:post_id/header_image/contexts`

Configured contexts come from `Railspress.image_contexts` (`hero`, `card`, and `thumb` by default).

- `GET /contexts` lists every configured context.
- `GET /contexts/:context` returns one context.
- `PUT` or `PATCH /contexts/:context` sets its behavior.
- `DELETE /contexts/:context` clears its custom override and returns to global focal behavior.

Each response reports the context name/label/aspect/sizes, whether it has an override, effective CSS, and effective image metadata.

### Use the global focal point

```json
{ "override": { "type": "focal" } }
```

This clears any custom context override.

### Set a normalized crop

```json
{
  "override": {
    "type": "crop",
    "region": {
      "x": 0.1,
      "y": 0.2,
      "width": 0.6,
      "height": 0.5
    }
  }
}
```

All values must be numeric within `0..1`; width and height must be greater than zero; and `x + width` plus `y + height` must remain inside the source image bounds.

### Use a context-specific upload

```json
{
  "override": {
    "type": "upload",
    "signed_blob_id": "eyJfcmFpbHMiOns..."
  }
}
```

`blob_signed_id` is accepted as a compatibility input alias. Responses use the canonical effective-image metadata rather than echoing upload parameters.

See [Image Focal Points](../image-focal-point-system.md) for host-side rendering and context configuration.
