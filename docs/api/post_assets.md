# Post Assets API (`v1`)

Base path: `/railspress/api/v1/post_assets`

Authentication: bearer token (see [authentication.md](authentication.md)).

Use this endpoint to upload an image before creating or updating a Post. The response includes canonical Action Text attachment markup that can be inserted into `post[content]` submitted as HTML.

Supported image types:

- JPEG
- PNG
- GIF
- WebP

## `POST /post_assets`

Upload an image with multipart form data:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "image=@./diagram.png" \
  "http://localhost:3000/railspress/api/v1/post_assets"
```

Both upload inputs may be nested under `asset` instead:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "asset[image]=@./diagram.png" \
  "http://localhost:3000/railspress/api/v1/post_assets"
```

An existing Active Storage direct-upload blob can instead be resolved with JSON. `asset[signed_blob_id]` is also accepted:

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"signed_blob_id":"eyJfcmFpbHMiOns..."}' \
  "http://localhost:3000/railspress/api/v1/post_assets"
```

Response (`201 Created`):

```json
{
  "data": {
    "blob_id": 45,
    "signed_blob_id": "eyJfcmFpbHMiOns...",
    "attachable_sgid": "BAh7CEkiCGdpZAY6BkVU...",
    "filename": "diagram.png",
    "byte_size": 214523,
    "content_type": "image/png",
    "attachment_html": "<action-text-attachment sgid=\"BAh7CEkiCGdpZAY6BkVU...\" ...></action-text-attachment>"
  }
}
```

Insert `attachment_html` unchanged at the desired location in an HTML post body, then submit that body using `content_format: "html"`. Action Text sanitizes the submitted body and associates a valid attachment SGID with the post's rich-text record when the Post is saved. Do not construct attachment tags from untrusted SGIDs.

Uploads that are never embedded remain unattached Active Storage blobs. Host applications should retain their normal unattached-blob cleanup policy.

This endpoint handles inline rich-text assets only. It is available independently of the post-image feature toggle. Use the feature-gated header-image and gallery-image resources documented in [Post Media](post_media.md) for those roles.
