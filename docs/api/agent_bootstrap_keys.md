# Agent Bootstrap Keys

Agent bootstrap keys are short-lived, one-time onboarding tokens.

- Token format: `rpb_<environment>_<prefix>_<secret>`
- Default expiration: 1 hour
- One-time exchange: once exchanged, token is invalid

Use bootstrap keys when you want to give an agent setup instructions without exposing a long-lived API key directly.

## Preferred RailsPress Agent Flow

The **Agents & API** page provides the exact token-free `RAILSPRESS.md` for the
host and mount. Save it at the publishing project root, review its normalized
values, and establish trust before using a credential:

```bash
"$HOME/.railspress/bin/railspress-agent" config check --start /path/to/project
"$HOME/.railspress/bin/railspress-agent" config trust --start /path/to/project
```

Then pipe the one-time token from its reveal page to the CLI:

```bash
export RAILSPRESS_BOOTSTRAP_TOKEN="rpb_test_..."
printf '%s\n' "$RAILSPRESS_BOOTSTRAP_TOKEN" \
  | "$HOME/.railspress/bin/railspress-agent" onboard --start /path/to/project --json
```

`onboard` refuses an existing token destination, makes exactly one exchange
request without redirects or retries, stores only the returned API key, rereads
it through the production credential checks, and verifies `/prime`.

If it reports `exchange_outcome_unknown`, do not repeat the bootstrap request.
Inspect or revoke any server-side API key and create a new bootstrap key. If it
reports `onboarding_incomplete` after `exchange_succeeded`, inspect/revoke the
minted key and follow the milestone-specific recovery output.

## Manual Exchange Endpoint

`POST /railspress/api/v1/agent_keys/exchange`

Authentication:

- `Authorization: Bearer <bootstrap_token>`

This raw HTTP example is the manual/no-agent fallback. It does not provide the
CLI's trust, response classification, storage, or recovery guarantees:

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

## Manual Token Storage

RailsPress Agent stores the long-lived API token in a site-scoped file under
`$HOME/.railspress/tokens`. The filename is derived from the API base URL's full
hostname, non-default port, and configured base path. This prevents one
RailsPress application from overwriting another application's token.

For a local application at `http://127.0.0.1:3129`, the generated commands are:

```bash
export RAILSPRESS_TOKEN_FILE="$HOME/.railspress/tokens/127.0.0.1-3129"
printf '%s\n' "$RAILSPRESS_TOKEN" \
  | "$HOME/.railspress/bin/railspress-agent" token store "$RAILSPRESS_TOKEN_FILE"
```

Direct file writes are a manual fallback and do not enforce all CLI ownership,
symlink, hard-link, containment, and atomic-publication checks.

Keep the bootstrap token transient. It is short-lived and one-time-use; only the exchanged API token belongs in the local token file.

## Admin Lifecycle

Admin endpoints:

- `GET /railspress/admin/agent_bootstrap_keys/new`
- `POST /railspress/admin/agent_bootstrap_keys`
- `POST /railspress/admin/agent_bootstrap_keys/:id/revoke`

UI location:

- `/railspress/admin/api_keys` (**Agents & API** page)
- Click **New Agent Key**

The one-time bootstrap token is only shown on create. The generic Agents & API
index intentionally uses a placeholder and never reconstructs an active token.
