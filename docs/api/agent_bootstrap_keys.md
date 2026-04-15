# Agent Bootstrap Keys

Agent bootstrap keys are short-lived, one-time onboarding tokens.

- Token format: `rpb_<environment>_<prefix>_<secret>`
- Default expiration: 1 hour
- One-time exchange: once exchanged, token is invalid

Use bootstrap keys when you want to give an agent setup instructions without exposing a long-lived API key directly.

## Exchange Endpoint

`POST /railspress/api/v1/agent_keys/exchange`

Authentication:

- `Authorization: Bearer <bootstrap_token>`

Example:

```bash
export RAILSPRESS_BOOTSTRAP_TOKEN="rpb_test_..."
curl -X POST \
  -H "Authorization: Bearer $RAILSPRESS_BOOTSTRAP_TOKEN" \
  http://localhost:3000/railspress/api/v1/agent_keys/exchange
```

Successful response (`201`) returns a one-time API key token:

```json
{
  "data": {
    "api_key": {
      "id": 42,
      "name": "Claude Code Setup (API Key)",
      "token": "rp_test_...",
      "expires_at": null
    },
    "bootstrap": {
      "id": 7,
      "used_at": "2026-04-15T15:00:00.000Z"
    }
  }
}
```

## Admin Lifecycle

Admin endpoints:

- `GET /railspress/admin/agent_bootstrap_keys/new`
- `POST /railspress/admin/agent_bootstrap_keys`
- `POST /railspress/admin/agent_bootstrap_keys/:id/revoke`

UI location:

- `/railspress/admin/api_keys` (**Agents & API** page)
- Click **New Agent Key**

The one-time bootstrap token is only shown on create.
