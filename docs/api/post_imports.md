# Post Imports API (`v1`)

Base path: `/railspress/api/v1/posts/imports`

Authentication: bearer token (see [authentication.md](authentication.md)).

Use this API when you want to create posts from markdown/text/zip attachments instead of JSON post payloads.

Supported file types:

- `.md` and `.markdown` (rendered as Markdown)
- `.txt` (escaped and preserved as literal plain text)
- `.zip` (for batch imports)

ZIP imports process Markdown and text files recursively. A `header_image` frontmatter value can reference an image inside the archive when post images are enabled. Relative inline Markdown images are not ingested as Action Text attachments; use the [Post Assets API](post_assets.md) when constructing rich content through the API.

## `POST /posts/imports`

Queues an async import job and returns an import status record.

Request options:

- multipart `file`
- JSON `signed_blob_id` (Active Storage direct upload)

Unlike the admin importer, which accepts multiple selected files in one operation, each API request accepts one file or signed blob. Submit multiple requests for multiple source files.

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

Import creation is asynchronous and is not idempotent. Retrying a request or a failed job can create duplicate posts because imports create new records rather than upserting by slug. Before retrying, inspect the import status and the posts it already created.
