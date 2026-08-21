# API Errors

All errors return JSON with an `error` object.

## Shape

```json
{
  "error": {
    "message": "Unauthorized"
  }
}
```

Validation failures include `details`:

```json
{
  "error": {
    "message": "Validation failed.",
    "details": [
      "Title can't be blank"
    ]
  }
}
```

## Status Codes

- `401 Unauthorized` - missing/invalid/revoked/expired API token
- `404 Not Found` - resource not found, API disabled, media feature disabled, or unknown image context
- `422 Unprocessable Content` - model validation failure, unsupported content format or file type, missing upload input, invalid signed blob, missing required attachment, or invalid focal/context values

Successful creates return `201 Created`, queued imports return `202 Accepted`, ordinary reads and updates return `200 OK`, and successful deletes return `204 No Content`.

Feature-gated post-media endpoints deliberately return `404` when the relevant capability is disabled. Clients should read [Prime](prime.md) before calling them. See [Post Media](post_media.md) for its route-specific errors.

| Endpoint area | Example `422` message |
| --- | --- |
| Post content | `Unsupported content format. Allowed: html, markdown, plain, auto.` |
| Post asset/gallery | `Either image or signed_blob_id is required.` |
| Post asset/gallery | `Unsupported image type. Allowed: JPEG, PNG, GIF, WebP.` |
| Header focal point/context | `Header image is not attached.` |
| Header context | `Crop region must include x, y, width, and height.` |

Treat `message` as human-readable context. Validation failures may also include `details`; clients should branch primarily on HTTP status and endpoint state rather than parsing message text.
