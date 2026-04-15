# Post Imports API (`v1`)

Base path: `/railspress/api/v1/posts/imports`

Authentication: bearer token (see [authentication.md](authentication.md)).

Use this API when you want to create posts from markdown/text/zip attachments instead of JSON post payloads.

Supported file types:

- `.md`
- `.markdown`
- `.txt`
- `.zip` (for batch imports)

## `POST /posts/imports`

Queues an async import job and returns an import status record.

Request options:

- multipart `file`
- JSON `signed_blob_id` (Active Storage direct upload)

### Multipart example

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -F "file=@./my-post.md" \
  "http://localhost:3000/railspress/api/v1/posts/imports"
```

### Signed blob example

```bash
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "signed_blob_id": "eyJfcmFpbHMiOns..."
  }' \
  "http://localhost:3000/railspress/api/v1/posts/imports"
```

Response (`202 Accepted`):

```json
{
  "data": {
    "id": 12,
    "import_type": "posts",
    "filename": "my-post.md",
    "content_type": "text/markdown",
    "status": "pending",
    "total_count": 0,
    "success_count": 0,
    "error_count": 0,
    "error_messages": [],
    "created_at": "2026-04-15T15:00:00.000Z",
    "updated_at": "2026-04-15T15:00:00.000Z"
  }
}
```

## `GET /posts/imports/:id`

Poll import progress and completion status.

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  "http://localhost:3000/railspress/api/v1/posts/imports/12"
```

Status values:

- `pending`
- `processing`
- `completed`
- `failed`
