# API Authentication

RailsPress API uses bearer tokens managed from admin.

## Enable API

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_api
  config.admin_authentication_method = :require_admin!
  config.current_admin_method = :current_user
  # Alternative for Current or other request-scoped identity:
  # config.current_admin_proc = -> { Current.user }
  # config.public_base_url = "https://blog.example.com"
end
```

RailsPress admin controllers inherit your host `ApplicationController`. `admin_authentication_method` names the host method that protects the browser UI, while `current_admin_method` names the host method that returns the administrator recorded on key lifecycle actions. If an inherited host callback already protects RailsPress, leave `admin_authentication_method` unset.

The former `current_api_actor_method` and `current_api_actor_proc` settings are deprecated compatibility aliases. They will be removed in RailsPress 2.0.

When generating admin API/agent instruction snippets, RailsPress resolves the base URL in this order:

1. `config.public_base_url` (if set)
2. `Rails.application.routes.default_url_options`
3. current request base URL

RailsPress also derives the optional local token filename from that resolved URL. It uses the full hostname, any non-default port, and any configured base path so credentials for separate applications do not overwrite one another. For example, `http://127.0.0.1:3129` uses `$HOME/.railspress/tokens/127.0.0.1-3129`, while `https://blog.example.com` uses `$HOME/.railspress/tokens/blog.example.com`.

## Mounting and Authentication Boundaries

Mount RailsPress normally, without wrapping the entire engine in a session or admin route constraint:

```ruby
Rails.application.routes.draw do
  mount Railspress::Engine => "/railspress"
end
```

RailsPress deliberately has two controller stacks:

- `/railspress/admin/*` inherits the host `ApplicationController` and invokes the configured host admin authentication method.
- `/railspress/api/*` inherits from `ActionController::API`, does not run host browser authentication callbacks, and enforces RailsPress bearer tokens (`401` without a valid token).

An outer route constraint executes before either controller stack and commonly rejects token-only API requests with `404`. Remove that constraint and use `config.admin_authentication_method` for the browser side instead.

## Active Record Encryption Requirement

`Railspress::ApiKey` and `Railspress::AgentBootstrapKey` store key secret material with Active Record Encryption.

RailsPress validates this requirement during boot whenever `config.enable_api` is enabled. It raises `Railspress::ConfigurationError` with the missing setting names and setup command, but never generates or writes credentials itself.

Generate the standard Rails credentials snippet:

```bash
bin/rails db:encryption:init
```

Store the generated values in the host application's environment credentials or deployment secret manager. Do not rotate existing encryption credentials merely to enable RailsPress; changing them can make existing encrypted data unreadable.

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

### 2) Agent Setup Key (bootstrap/onboarding token)

- Format: `rpb_<environment>_<prefix>_<secret>`
- Exchange-only token for `POST /api/v1/agent_keys/exchange`
- Default expiration: 1 hour
- One-time use

## Bootstrap Exchange Flow

1. Create a key in admin (`/railspress/admin/api_keys`) via **New Agent Setup Key** on the **Agents & API** page.
2. Save the token-free `RAILSPRESS.md` from that page in the publishing project,
review it, and establish trust.
3. Use the preferred RailsPress Agent connection command for trust approval,
one-time exchange, secure storage, and `/prime` verification:

```bash
export RAILSPRESS_BOOTSTRAP_TOKEN="rpb_test_..."
printf '%s\n' "$RAILSPRESS_BOOTSTRAP_TOKEN" \
  | "$HOME/.railspress/bin/railspress-agent" connect --start /path/to/project --json
```

For already trusted/headless automation, `onboard` remains the lower-level
exchange command.

The exchange is atomically claimed by the engine. Concurrent or replayed use
cannot mint another API key. Never automatically retry an unknown outcome;
inspect/revoke the potentially created key and generate a new bootstrap token.

4. A direct API key can be stored through the same hardened CLI boundary:

```bash
export RAILSPRESS_TOKEN_FILE="$HOME/.railspress/tokens/localhost-3000"
printf '%s\n' "$RAILSPRESS_TOKEN" \
  | "$HOME/.railspress/bin/railspress-agent" token store "$RAILSPRESS_TOKEN_FILE"
```

The **Agents & API** admin page generates the correct scoped path for the configured public URL or current request, so prefer its copy-ready instructions over constructing this filename manually.

5. Returning sessions verify connectivity and capabilities before writes:

```bash
"$HOME/.railspress/bin/railspress-agent" prime --start /path/to/project --json
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
