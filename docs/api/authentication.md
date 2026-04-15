# API Authentication

RailsPress API uses bearer tokens managed from admin.

## Enable API

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_api
  config.current_api_actor_method = :current_user
  # config.current_api_actor_proc = -> { Current.user }
  # config.public_base_url = "https://blog.example.com"
end
```

When generating admin API/agent instruction snippets, RailsPress resolves the base URL in this order:

1. `config.public_base_url` (if set)
2. `Rails.application.routes.default_url_options`
3. current request base URL

## Active Record Encryption Requirement

`Railspress::ApiKey` and `Railspress::AgentBootstrapKey` store key secret material with Active Record Encryption.

Configure encryption keys in your application:

```ruby
Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
```

## Two Token Types

### 1) API Key (direct API access)

- Format: `rp_<environment>_<prefix>_<secret>`
- Used for all content endpoints (`/api/v1/posts`, `/api/v1/categories`, etc.)
- Default expiration: none (unless set at creation)

### 2) Agent Bootstrap Key (onboarding token)

- Format: `rpb_<environment>_<prefix>_<secret>`
- Exchange-only token for `POST /api/v1/agent_keys/exchange`
- Default expiration: 1 hour
- One-time use

## Bootstrap Exchange Flow

1. Create a key in admin (`/railspress/admin/api_keys`) via **New Agent Key** on the **Agents & API** page.
2. Exchange bootstrap key for API key:

```bash
export RAILSPRESS_BOOTSTRAP_TOKEN="rpb_test_..."
export RAILSPRESS_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer ${RAILSPRESS_BOOTSTRAP_TOKEN}" \
  http://localhost:3000/railspress/api/v1/agent_keys/exchange \
  | ruby -rjson -e 'print JSON.parse(STDIN.read).dig("data","api_key","token")')
```

3. Optional local token file:

```bash
printf '%s\n' "$RAILSPRESS_TOKEN" > ~/.railspress_token
chmod 600 ~/.railspress_token
export RAILSPRESS_TOKEN="$(cat ~/.railspress_token)"
```

4. Verify connectivity:

```bash
curl -H "Authorization: Bearer $RAILSPRESS_TOKEN" \
  http://localhost:3000/railspress/api/v1/prime
```

## Admin Lifecycle Endpoints

API keys:

- `GET /railspress/admin/api_keys`
- `POST /railspress/admin/api_keys`
- `POST /railspress/admin/api_keys/:id/rotate`
- `POST /railspress/admin/api_keys/:id/revoke`

Bootstrap keys:

- `GET /railspress/admin/agent_bootstrap_keys/new`
- `POST /railspress/admin/agent_bootstrap_keys`
- `POST /railspress/admin/agent_bootstrap_keys/:id/revoke`

## Behavior Summary

- Any signed-in RailsPress API actor can create/rotate/revoke keys.
- Token plaintext is shown once at create/rotate/exchange.
- API keys are full-access for exposed v1 resources.
- Bootstrap keys cannot call content endpoints directly.
- Bootstrap keys are short-lived by default (1 hour).
