# API Authentication

RailsPress API uses bearer tokens created from the admin UI.

## Enable API

```ruby
# config/initializers/railspress.rb
Railspress.configure do |config|
  config.enable_api
  config.current_api_actor_method = :current_user
  # config.current_api_actor_proc = -> { Current.user }
end
```

## Active Record Encryption Requirement

`Railspress::ApiKey` stores key secret material using Active Record Encryption (`encrypts :secret`).

Configure encryption keys in your application (example with credentials/env):

```ruby
Rails.application.config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT")
```

## Key Lifecycle (Admin)

Admin endpoints:

- `GET /railspress/admin/api_keys`
- `POST /railspress/admin/api_keys`
- `POST /railspress/admin/api_keys/:id/rotate`
- `POST /railspress/admin/api_keys/:id/revoke`

Behavior:

- Any signed-in RailsPress admin actor can create, rotate, and revoke keys.
- Owner metadata is recorded at creation time.
- Rotating creates a new key and revokes the previous key.
- Token plaintext is shown once (create/rotate response only).

## Using a Token

Send the token with `Authorization: Bearer <token>`.

```bash
curl -H "Authorization: Bearer rp_test_..." \
  http://localhost:3000/railspress/api/v1/posts
```

Token format:

```text
rp_<environment>_<prefix>_<secret>
```
