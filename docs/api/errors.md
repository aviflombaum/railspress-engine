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
- `404 Not Found` - resource not found, or API not enabled
- `422 Unprocessable Content` - validation failure
