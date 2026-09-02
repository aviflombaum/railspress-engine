---
title: RailsPress 1.5.0 agent API improvements
type: research
status: proposed
date: 2026-09-02
engine_version: 1.5.0
engine_commit: e4d16fd52d04aba5b14763d83d60aeb99fc567c7
agent_version: 0.3.0
agent_commit: 9f13144a1ef5e49b51215b9679546ea3896d286e
---

# RailsPress 1.5.0 Agent API Improvements

## Purpose

This document translates the recommendations in:

- `/Users/avi/Development/code/RailsPress/railspress-agent-improvements.md`; and
- `/Users/avi/Development/code/RailsPress/railspress-feedback.md`

into a concrete ownership boundary between RailsPress Engine, RailsPress Agent
CLI, and the installed agent skill. It is an implementation-direction document,
not an assertion that the changes described here already exist.

The main conclusion is:

> RailsPress Engine must define and enforce the live publishing contract.
> RailsPress Agent must be the sole authenticated client that executes that
> contract. The installed skill should only translate user intent and authority
> into CLI commands.

The engine should not absorb local credential, trust, transport, installer, or
agent-runtime concerns. The CLI should not invent server validation, URLs,
permissions, idempotency, or concurrency semantics. Both sides need work for the
target experience, but their work can proceed in independently useful slices.

## Sources and audited state

This research inspected the engine and agent repositories at the commits in the
frontmatter, including routes, API controllers, key models, API request specs,
engine API documentation, CLI command dispatch, HTTP handling, Prime validation,
and the Codex and Claude adapters.

### Engine 1.5.0 today

The engine already provides a useful v1 foundation:

- bearer-authenticated post, media, import, category, and tag endpoints;
- one-time Agent Setup Key exchange into a normal API key;
- atomic bootstrap-key claiming, so concurrent exchange cannot mint two keys;
- API keys stored as keyed digests rather than recoverable plaintext;
- a `/prime` handshake with API major, defaults, feature capabilities, mounted
  endpoint paths, current-key status, and server time;
- draft-by-default post creation and explicit `published` status;
- Markdown, plain-text, HTML, and automatic content conversion;
- pagination metadata on post, category, and tag collections; and
- feature-gated media capabilities.

The engine does not yet provide:

- an operation-level machine contract or request/response schemas;
- effective authorization distinct from engine capability;
- API-key scopes (all current API keys have full v1 access);
- idempotency for posts, imports, assets, categories, tags, or gallery creates;
- stable error codes or structured field errors;
- response request IDs in the JSON contract;
- `Location` headers or actionable resource links;
- transformation metadata for canonicalized content;
- ETags or `If-Match` update protection;
- advertised payload, upload, pagination, sorting, or field limits; or
- a device/browser authorization flow.

There is also a small contract inconsistency: `/prime` advertises both
`api_key` and `agent_bootstrap_key` under `authentication.token_types`, but
`PrimeController` inherits API-key authentication and cannot be called with an
Agent Setup Key. Bootstrap keys are valid only at the exchange endpoint. The
contract should state that distinction directly.

### RailsPress Agent 0.3.0 today

The CLI already owns installation, adapter lifecycle, manifest validation,
local trust, secure credential storage, one-time onboarding, and authenticated
Prime retrieval. Its HTTP client rejects redirects, disables automatic retries,
bounds response size, enforces HTTPS except for loopback, validates JSON media
types, and keeps bearer values out of output.

The executable command surface ends at:

- `connect`;
- `prime`; and
- `onboard`.

It has no content `request` command and no `posts`, `imports`, `assets`,
`categories`, `tags`, or media commands. Its HTTP client only implements the
limited GET/empty-POST behavior needed by Prime and bootstrap exchange. It does
not yet serialize content bodies, multipart uploads, idempotency headers,
conditional updates, or content-operation results.

The Codex and Claude `SKILL.md` files are currently identical. Both still tell
the model how to read the managed token and construct authenticated content HTTP
after Prime succeeds. That is the boundary that needs to close.

## Responsibility boundary

| Concern | Engine | Agent CLI | Installed skill |
| --- | --- | --- | --- |
| Supported resources and operations | Define and advertise | Validate and invoke | Select from user intent |
| Request/response schema | Define and validate | Serialize and validate | Prepare content/input |
| Feature capability | Compute from live engine config | Gate command locally | Avoid unavailable workflows |
| Key authorization | Enforce and advertise | Gate command locally | Do not infer permission |
| Draft/publish semantics | Enforce draft default | Require explicit publish input | Require explicit user authority |
| Delete semantics | Enforce authorization | Require exact resource confirmation | Require explicit user authority |
| Idempotency | Persist and replay safely | Generate, retain, and reconcile keys | Never blindly retry unknown writes |
| Optimistic concurrency | Emit validators and enforce `If-Match` | Send validators and report conflicts | Ask user how to resolve conflicts |
| Stable API errors | Produce code, fields, retry metadata | Preserve and wrap safely | Follow code/next action |
| Resource URLs | Generate canonical same-origin links | Verify before displaying | Present useful links |
| Manifest discovery | None | Own | Ask CLI to discover |
| Local trust binding | None | Own | Never bypass |
| Credential storage and reading | Issue/revoke server keys | Own exclusively | Never read a token |
| Authenticated HTTP transport | Respond and enforce | Own exclusively | Never construct it |
| Redirect, timeout, and retry policy | Return normal HTTP semantics | Own | Never reproduce in shell |
| CLI JSON envelope and exit codes | None | Own | Consume without message parsing |
| Runtime adapters and installation | Generate compatible setup guidance only | Own | Thin runtime-specific entry point |
| Human approval and intent | Admin UI where server action is needed | Prompt/require flags locally | Interpret explicit user request |

This boundary means that an engine feature is not complete merely because a
route exists. The engine must expose enough machine-readable semantics for a
safe client to use the route without source inspection. Conversely, the engine
does not need to understand Codex, Claude, local token files, shell behavior, or
CLI installation state.

## Engine work

### P0: provide stable request and error identity

Every API response should expose the Rails request ID in both the
`X-Request-Id` header and JSON where a body exists. Error responses should retain
the current human-readable `message` and `details` fields for additive v1
compatibility while adding stable fields:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed.",
    "field_errors": {
      "title": ["blank"]
    },
    "details": ["Title can't be blank"],
    "retryable": false,
    "request_id": "3c15b8d3-..."
  }
}
```

Initial stable codes should cover:

- `authentication_required` for missing, malformed, expired, or revoked API
  credentials;
- `api_disabled` when the API is not enabled;
- `resource_not_found`;
- `capability_disabled` for feature-gated routes;
- `operation_forbidden` when scoped authorization is introduced;
- `validation_failed`;
- `unsupported_content_format`;
- `unsupported_media_type`;
- `invalid_signed_blob`;
- `idempotency_conflict`;
- `precondition_required` and `precondition_failed`; and
- `rate_limited` if RailsPress itself later adds rate limiting.

Do not claim that an error is retryable merely because it is a `5xx`. Whether a
write can be retried depends on idempotency and whether the server committed it.
The CLI owns transport-outcome classification; the engine supplies request and
idempotency identity for reconciliation.

Likely touchpoints:

- `app/controllers/railspress/api/v1/base_controller.rb`;
- all feature-gate helpers that currently return message-only `404` responses;
- request specs for every API area; and
- `docs/api/errors.md`.

### P0: add server-side idempotency for creates

The engine must support `Idempotency-Key` on creation operations whose replay
could duplicate durable state:

- `posts.create`;
- `post_imports.create`;
- `post_assets.create`;
- `post_gallery_images.create`;
- `categories.create`; and
- `tags.create`.

The server should scope a key to the authenticated API key and operation, store
a canonical request digest, and retain the original status and response for a
documented window. A same-key/same-payload replay returns the original semantic
result and marks `meta.idempotency_replayed: true`. A same-key/different-payload
replay returns `idempotency_conflict` without executing the operation.

The implementation needs a migration and a namespaced model, for example an
idempotency record containing:

- API key association;
- operation identifier;
- idempotency key or keyed digest;
- canonical request digest;
- lifecycle state (`processing`, `completed`);
- response status and replayable response body/resource identity;
- original request ID; and
- expiry timestamp.

The unique index must make claiming atomic. The implementation must define how
an in-progress duplicate is reported and must not hold a database transaction
open while an asynchronous import job executes. For imports, idempotency covers
creation and enqueueing of the import record, not completion of the import.

Multipart request digests should be based on stable metadata plus file bytes,
not a temporary path. A signed-blob request should digest the signed identifier
and semantic request fields. Responses that expose expiring signed IDs may need
to be regenerated from the recorded resource rather than persisted verbatim.

The CLI can ship before this is available, but it must then label affected
timeouts as `outcome_unknown` and refuse automatic retry. Full safe retry and
reconciliation require this engine change.

### P0: return safe actionable links and creation locations

Successful creates should set `Location` to the new API resource when the
resource has an API show route. Resource serialization should add server-built
same-origin links rather than forcing the CLI to guess host mounts or public
routes.

For posts, the safe default response should provide:

```json
{
  "data": {
    "id": 31,
    "links": {
      "api": "https://avi.nyc/railspress/api/v1/posts/31",
      "admin": "https://avi.nyc/railspress/admin/posts/31",
      "admin_edit": "https://avi.nyc/railspress/admin/posts/31/edit",
      "public": null
    }
  }
}
```

`public` should be non-null only when the post is actually live. It must use the
configured public base URL and `blog_path`, not assume the engine mount is the
public blog path.

A draft preview URL must **not** be included automatically. RailsPress preview
URLs contain a signed bearer credential. Automatically returning one would put
that credential in normal CLI output and agent transcripts. Instead, advertise
preview support and add an explicit operation that mints an expiring preview
link only when the user asks for one. That operation should return its expiry
and be classified as sensitive output by the CLI.

The same link convention should be used for imports and taxonomies where useful.
For a queued import, `Location` should identify the import status endpoint.

Likely touchpoints:

- `app/controllers/railspress/api/v1/concerns/post_serialization.rb`;
- create actions in API controllers;
- a shared URL/link builder that accounts for engine mount and
  `Railspress.public_base_url`;
- a new explicit preview-link route if included in 1.5.0; and
- API response documentation and request specs.

### P1: publish an operation contract

`/prime` currently says which broad features exist and supplies collection
paths. It does not tell the client the method, member-path template, request
envelope, accepted fields, success statuses, safety class, idempotency support,
or response shape for a specific operation.

For 1.5.0, prefer a compact RailsPress operation contract over introducing a
large generated OpenAPI dependency. Prime should remain the fresh, small
handshake and advertise a same-origin contract endpoint with an immutable
digest:

```json
{
  "data": {
    "version": "v1",
    "contract": {
      "version": 1,
      "url": "/railspress/api/v1/contract",
      "sha256": "..."
    }
  }
}
```

The authenticated contract document should include an operation registry and
JSON-schema-compatible request/response definitions. A representative operation
entry is:

```json
{
  "operations": {
    "posts.create": {
      "method": "POST",
      "endpoint": "posts",
      "request_schema": "#/schemas/post_create_request",
      "success_statuses": [201],
      "content_types": ["application/json", "multipart/form-data"],
      "safety": "write_non_destructive",
      "confirmation": "none",
      "idempotency": {
        "supported": true,
        "header": "Idempotency-Key"
      }
    }
  }
}
```

The contract needs to describe:

- collection and member endpoint templates;
- method and accepted content types;
- request envelope and required/optional/mutable/nullable fields;
- enum values and feature-conditional fields;
- success status and response schema;
- maximum JSON body, upload, archive-expanded, page-size, tag-count, and content
  sizes where the engine enforces them;
- pagination, filtering, allowed sort keys, and sort directions;
- draft and explicit-publish rules;
- safety classification and confirmation expectations;
- idempotency and conditional-update support; and
- whether returned content is transformed.

The digest lets the CLI cache an unchanged contract without using a stale Prime
response. Before a write, the CLI still performs a fresh Prime request, checks
the advertised digest and effective authorization, and fetches the contract only
when needed. The engine remains the source of truth.

The registry should be defined once in engine code and used to construct both
the contract and Prime authorization lists. Avoid maintaining an unrelated copy
of controller behavior in documentation.

### P1: distinguish capabilities from effective authorization

Capabilities answer what this configured engine installation supports.
Authorization answers what the authenticated key may do. Prime needs both:

```json
{
  "capabilities": {
    "posts": { "create": true, "delete": true }
  },
  "authorization": {
    "model": "full_access_v1",
    "scopes": ["*"],
    "effective_operations": [
      "posts.list",
      "posts.show",
      "posts.create",
      "posts.update",
      "posts.delete"
    ]
  }
}
```

This can be added without introducing scoped keys in 1.5.0. Existing keys are
full-access, so the engine can initially derive all effective operations from
live feature capabilities and advertise `full_access_v1`. This immediately
gives the CLI a stable authorization interface.

Fine-grained scopes should be a later additive engine feature unless restricted
keys are a 1.5.0 product requirement. It requires API-key schema, issuance UI,
rotation behavior, enforcement in `BaseController`, bootstrap-created-key
defaults, and migration/backfill decisions. Do not make the CLI wait for it and
do not advertise fictitious restrictions before enforcement exists.

### P1: add content transformation metadata

Post create and update should report what happened to submitted content:

```json
{
  "meta": {
    "request_id": "...",
    "transformation": {
      "input_content_format": "markdown",
      "stored_content_format": "html",
      "source_retained": false
    }
  }
}
```

The formatter already knows the requested/normalized input format. Preserve it
through the action long enough to construct response metadata. Keep
`data.content_format: "html"`, because that accurately describes the returned
canonical body.

### P1: add optimistic concurrency for updates

At minimum, post reads and updates should support ETags and `If-Match`:

- show/create/update returns an ETag or explicit representation version;
- update requires or accepts `If-Match` according to the advertised operation
  contract;
- a stale validator returns `412 Precondition Failed` with
  `precondition_failed` and the current validator;
- if strict preconditions are enabled, a missing validator returns `428
  Precondition Required`; and
- the CLI can re-read and ask whether to merge or overwrite.

Using an explicit `lock_version` is more reliable than deriving concurrency only
from timestamp precision. If RailsPress uses `lock_version`, add it to posts and
include it in the ETag calculation. Media and focal-point operations that mutate
the effective post representation must also touch or version the post before
the same concurrency guarantee can be claimed for them.

Apply concurrency first to `posts.update`, where silent human/agent overwrite is
most harmful. Category and tag updates can follow through the same shared
pattern.

### P1: correct and enrich Prime

Prime should remain authenticated, fresh, bounded, and additive. Its revised
responsibilities should be:

- API major and engine build/version metadata;
- authentication methods with endpoint-specific token use;
- current key status and normalized expiry;
- defaults and explicit-publish behavior;
- live feature capabilities;
- effective operations for the current key;
- the operation-contract URL, version, and digest;
- limits that affect handshake/client behavior; and
- server time and request ID.

Correct the authentication description so it does not imply that bootstrap keys
can authenticate Prime or content endpoints. For example:

```json
{
  "authentication": {
    "content": { "type": "bearer", "token_type": "api_key" },
    "bootstrap_exchange": {
      "type": "bearer",
      "token_type": "agent_bootstrap_key",
      "endpoint": "/railspress/api/v1/agent_keys/exchange"
    }
  }
}
```

Keep the current `endpoints` and capability fields during v1 so Agent 0.3.0
continues to work.

### P2: improve onboarding and recovery generated by the engine

The engine owns the admin setup packet and any server-side approval flow. It
should stop encouraging users to paste the Agent Setup Key into an agent chat or
put it in an exported shell variable. The preferred reveal-page guidance should
be:

1. Save the exact, complete, token-free `RAILSPRESS.md` block in the publishing
   project.
2. Open a local terminal in that project.
3. Run `railspress-agent connect`.
4. Enter the Agent Setup Key at the CLI's hidden prompt.
5. Tell the coding agent only that RailsPress is connected.

The current stdin form should remain documented for controlled automation, but
it should not be the prominent copy block. The manifest copy should include the
full explanatory text from the feedback and clearly state that it is safe to
commit.

Unknown bootstrap-exchange recovery should expose non-secret identifiers:

- bootstrap key ID or fingerprint;
- expiry;
- request/correlation ID;
- whether an API key was minted, without revealing it; and
- a precise admin URL/action to revoke the possible key before generating a new
  setup key.

The engine currently retains `exchanged_api_key_id`, which is a good basis for
admin recovery. It needs a recovery-oriented response/UI contract, not another
copy of the minted secret.

### P2: device/browser authorization, if selected

A device flow spans both repositories but its durable authority belongs to the
engine. The engine would need:

- a short-lived authorization transaction model;
- a public initiation endpoint that returns a non-secret user code and
  verification URL;
- an authenticated admin approval screen showing project/connection details;
- a bounded polling/token endpoint;
- single-use, expiry, denial, and replay semantics;
- API-key issuance tied to the approving administrator; and
- audit and recovery UI.

The CLI would initiate and poll the transaction. The skill would only tell the
user where approval is needed. This is valuable, but it is larger than the
core content-client boundary and should not block CLI content commands.

## Agent CLI work

### P0: make the CLI the only authenticated content client

Add a constrained operation command first:

```sh
railspress-agent request \
  --start . \
  --operation posts.create \
  --input post.json \
  --json
```

It must accept an advertised operation identifier, never an arbitrary URL. The
CLI resolves the operation through fresh Prime plus the engine contract, checks
capability and effective authorization, loads the managed token internally, and
executes the request with its existing same-origin/no-redirect/no-retry safety.

The HTTP layer needs to grow beyond its current Prime/bootstrap methods to
support:

- GET, POST, PATCH/PUT, and DELETE according to the contract;
- JSON body streaming from a file or stdin;
- bounded multipart uploads without exposing tokens to a child `curl` process;
- request and response byte limits;
- expected success statuses including empty `204` bodies;
- response headers such as `Location`, `ETag`, `Retry-After`, and
  `X-Request-Id`;
- `Idempotency-Key` and `If-Match`;
- stable engine error parsing; and
- recursive redaction on all result and diagnostic paths.

Every write should internally run a fresh Prime check. Reads may use the same
path for consistency, although a product decision can allow a bounded cached
contract when Prime's digest is unchanged.

### P0: standardize CLI outcomes and JSON envelopes

CLI JSON is a client contract distinct from the engine response contract. Every
machine-facing command should emit exactly one token-free object on stdout for
success and failure. A content result should include:

- command and CLI version;
- manifest path and normalized connection/fingerprint;
- operation;
- resource data and verified safe links;
- engine request ID;
- idempotency key and replay state;
- ETag/version where applicable;
- one of `request_not_started`, `definite_failure`, `outcome_unknown`, or
  `confirmed`;
- stable CLI/engine error code;
- retryability; and
- a machine-readable `next_action`.

The CLI, not the engine, decides `outcome_unknown`, because only the client knows
whether it lost the connection before receiving a definitive response. It must
never automatically retry an unknown write. With server idempotency, the next
action can reconcile or repeat with the same key; without it, the next action
must instruct the agent to inspect server state.

Normalize the connection object across `connect`, `config check`, `prime`, and
new commands. Existing 0.3.0 shapes can be kept behind a compatibility contract
or changed in a documented Agent minor release.

### P0: add first-class post commands

Layer domain commands on the tested request core:

```sh
railspress-agent posts list --start . --json
railspress-agent posts show 31 --start . --json
railspress-agent posts create --start . --input post.json --json
railspress-agent posts update 31 --start . --input update.json --json
railspress-agent posts delete 31 --start . --confirm-id 31 --json
```

Behavior belongs in the CLI as follows:

- omitted create status remains omitted so the engine's draft default applies;
- an explicit `--publish` or `status: published` is required for publication;
- deletion requires the exact resource ID, not a reusable global `--yes`;
- update carries the last observed ETag through `If-Match`;
- create retains its idempotency key until a definitive result;
- errors preserve engine codes and add safe recovery guidance; and
- response links are accepted only after same-origin validation.

The engine still independently enforces defaults, authorization, idempotency,
and concurrency. CLI checks improve safety and feedback but are not the security
boundary.

### P1: add remaining domain commands

After posts, add commands for:

- imports create/show and polling;
- inline assets upload;
- categories and tags list/show/create/update/delete;
- gallery list/add/delete;
- header image show/set/delete;
- focal point show/update; and
- context list/show/update/clear.

Keep every optional operation capability-gated. Uploads must stay in-process or
use a carefully designed secret-free helper protocol; the CLI must never place a
bearer value in child-process arguments or environment.

### P1: verification and compact output

Add:

```sh
railspress-agent verify --start . --json
railspress-agent prime --for posts.create --summary --json
```

`verify` owns local installation/adapter/manifest/trust/token-integrity checks
and combines them with fresh API/key/authorization/contract compatibility.
The engine only supplies the server half through Prime.

Operation-focused Prime output is a CLI projection. It must still contact the
server and validate the full response internally before returning only the
facts relevant to the selected operation.

### P1: hidden setup input and connection planning

Interactive `connect` should read the Agent Setup Key from the controlling
terminal with echo disabled. Retain stdin for deliberate headless automation.
Add a token-free `connect plan` result with the normalized connection and
fingerprint so approval can be audited separately from exchange.

This is CLI work. The engine only needs to generate guidance compatible with it
and provide better recovery identity. A browser/device flow would add the
engine endpoints described above.

### P1: one canonical skill and compatibility metadata

The agent repository should maintain one canonical skill source and generate or
contract-test Codex and Claude adapters. Runtime-specific adapters should only
contain host-format differences.

Add explicit metadata such as:

```yaml
railspress_agent:
  minimum_version: 0.4.0
  maximum_api_major: v1
  skill_contract_version: 2
```

The CLI should report adapter/core/API skew. The engine should advertise its API
and operation-contract versions, but it should not know which agent runtimes are
installed.

### P2: distribution hardening

Signed release manifests, provenance, SBOMs, immutable download URLs, package
manager distribution, installer integrity reporting, and runtime adapter
registries belong entirely to the agent repository. The engine's only role is
to generate setup instructions that pin a compatible release when appropriate
and link to authoritative installation documentation.

## Installed skill after the CLI changes

The installed skill should become short enough to describe policy rather than
reimplement a client. It should:

1. Identify the publishing project through the CLI.
2. Use `verify` for connection diagnosis.
3. Select a domain command from the user's intent.
4. Prepare a structured content input file or stdin document.
5. Default ambiguous creation to draft.
6. Require explicit authority for publishing and exact-resource deletion.
7. Never retry `outcome_unknown` without following reconciliation guidance.
8. Present the CLI's safe resource links and next action.

It should not:

- open or validate a token file;
- put a bearer value in argv, environment, logs, or a request payload;
- call `curl` for authenticated RailsPress requests;
- concatenate API paths;
- reproduce redirects, timeouts, content-type, or response-size policy;
- infer capability or key authorization; or
- parse human error messages to choose behavior.

## Coordinated delivery plan

The repositories do not need a single all-or-nothing release. The safest useful
sequence is:

### Slice 1: close the client boundary without waiting for engine redesign

Agent repository:

- implement the constrained request core against the existing v1 Prime and
  endpoint fields;
- add post list/show/create/update/delete commands;
- add stable CLI envelopes and outcome classification; and
- update the skills so no agent handles an API token or direct HTTP.

Engine repository:

- preserve the current v1 Prime fields and endpoints;
- add request IDs and additive stable error codes; and
- add `Location` plus safe API/admin/public links.

The first CLI release may contain a reviewed v1 operation mapping because the
current engine does not advertise methods and schemas. That mapping must be
strictly versioned and replaced by contract discovery when available; it must
never accept arbitrary URLs.

### Slice 2: make writes repeatable and discoverable

Engine repository:

- add idempotency storage and create-action integration;
- add the operation contract endpoint and Prime digest;
- add effective authorization reporting; and
- publish enforced limits.

Agent repository:

- consume the operation contract;
- generate and retain idempotency keys;
- reconcile repeats and unknown outcomes; and
- remove hard-coded v1 operation details where contract discovery replaces
  them.

### Slice 3: protect concurrent editing and finish post ergonomics

Engine repository:

- add post representation versions/ETags and `If-Match` enforcement;
- add transformation metadata; and
- add the explicit preview-link operation if desired.

Agent repository:

- carry validators through updates;
- provide conflict recovery without silent overwrite; and
- add explicit preview-link retrieval with sensitive-output handling.

### Slice 4: expand domains and improve onboarding

Agent repository:

- add import, asset, taxonomy, and media commands;
- add `verify`, compact operation output, canonical skills, and compatibility
  reporting; and
- use hidden interactive setup input.

Engine repository:

- update admin-generated setup/recovery instructions;
- expose bootstrap correlation and recovery links; and
- add a device/browser authorization flow only if selected.

### Slice 5: scoped keys and distribution hardening

Scoped API keys are an engine/API/admin feature. Signed releases, packaging,
provenance, and adapter registries are agent-distribution features. Neither
should block closing the authenticated content boundary.

## Engine compatibility and migration notes

Most proposed v1 response work can remain additive:

- preserve existing `data`, `error.message`, `error.details`, `capabilities`,
  and `endpoints` fields;
- add `error.code`, `field_errors`, `meta`, `links`, `authorization`, and
  `contract`;
- add response headers without requiring old clients to send new headers; and
- keep current routes while adding contract or preview-link routes.

Behavior changes need explicit rollout decisions:

- Idempotency needs a new engine migration and retention cleanup policy.
- `lock_version` needs a migration if used for posts.
- Requiring `If-Match` immediately would break current clients. Initially
  advertise and accept it, then require it only in a later API contract or when
  the client opts into strict concurrency.
- Fine-grained key scopes need schema, backfill, admin UI, and enforcement. Old
  keys should retain full v1 access unless an administrator changes them.
- Preview URLs are credentials and should be opt-in, not additive fields on
  every ordinary post response.

The operation contract should have its own integer contract version and digest
inside API major v1. Additive operations or optional fields can change the
digest without changing API major. Incompatible request/response semantics need
a new contract version and eventually a new API major.

## Engine code map

Expected engine areas for implementation planning:

| Area | Likely files |
| --- | --- |
| Common errors/request metadata | `app/controllers/railspress/api/v1/base_controller.rb` |
| Prime/auth/authorization contract | `app/controllers/railspress/api/v1/prime_controller.rb` |
| Operation registry/contract route | new API contract class/controller plus `config/routes.rb` |
| Idempotency | new model, concern/service, migration, create controllers |
| Post links/transformation/concurrency | posts controller, post serialization concern, `Post`, migration |
| Import `Location` and replay | post imports controller and import specs |
| Asset/taxonomy/media replay | corresponding API controllers and request specs |
| Key scopes, if selected | `ApiKey`, key migration, admin controllers/views, API base controller |
| Setup and recovery copy | admin API-key/bootstrap-key controllers and reveal/index views |
| Public configuration | initializer template and `docs/CONFIGURING.md` if new settings are added |
| API docs | `docs/api/prime.md`, `errors.md`, resource docs, upgrading guide |

## Required engine tests

Follow the repository request-spec conventions and use fixtures for persistent
test data. At minimum, add coverage proving:

### Prime and contract

- Prime retains the existing v1 fields for Agent 0.3.0.
- Bootstrap keys are described as exchange-only, not Prime/content credentials.
- Capabilities reflect live engine flags.
- Effective operations omit feature-disabled operations.
- The contract URL is mounted correctly and cannot change origin.
- The advertised digest matches the exact contract response.
- Every advertised operation maps to a real route and documented method.

### Errors and identity

- Every JSON error has a stable code, request ID, and retry metadata.
- Validation responses include field error codes plus existing human details.
- Authentication, API disabled, missing resource, feature disabled, and invalid
  input are distinguishable without message parsing.
- The JSON request ID matches `X-Request-Id`.

### Idempotency

- Same API key, operation, idempotency key, and payload returns one resource.
- The replay response identifies that it was replayed.
- Reuse with a different payload returns `idempotency_conflict`.
- The same idempotency key may be used by a different API key without collision.
- Concurrent claims cannot execute twice.
- Import replay does not enqueue two jobs.
- Multipart and signed-blob request digests are stable.

### Posts and concurrency

- Omitted status still creates a draft.
- Explicit published status still publishes.
- Markdown returns canonical HTML plus transformation metadata.
- Create returns `Location` and safe same-origin links.
- Draft responses do not expose a preview bearer token by default.
- A matching `If-Match` updates the post.
- A stale `If-Match` cannot overwrite a concurrent human edit.

### Onboarding and recovery

- Generated default instructions do not place a setup key in an agent-oriented
  prompt or exported environment variable.
- The manifest block is exact, token-free, and mount-aware.
- Exchange responses and admin state share a non-secret recovery identifier.
- No recovery screen redisplays an API key.

Cross-repository contract tests should additionally run the released Agent
0.3.0 Prime client against the revised engine and the next Agent client against
both the pre-improvement and improved v1 engine fixtures.

## Decisions for 1.5.0

Recommended decisions:

1. Treat CLI-owned authenticated content operations as the immediate priority.
   The engine should enable them, not duplicate them.
2. Keep API v1 additive and preserve the current Prime baseline.
3. Add stable API errors, request identity, locations, and safe links first.
4. Add durable idempotency before describing creates as safely retryable.
5. Use a compact versioned operation contract plus digest for 1.5.0; defer full
   OpenAPI generation unless another consumer needs it.
6. Advertise current full-access effective authorization now; defer scoped-key
   product work rather than blocking the CLI.
7. Add post concurrency incrementally and do not require `If-Match` from legacy
   clients in the same additive release.
8. Do not put signed preview URLs into default API/CLI output.
9. Change admin setup guidance so the human enters setup secrets directly into
   the CLI, while retaining stdin automation as an advanced flow.
10. Do not let device authorization or distribution hardening delay the core
    content-client boundary.

## Completion criteria

The improved architecture is complete when:

- no installed skill reads a RailsPress token;
- no coding agent constructs an authenticated RailsPress HTTP request;
- all authenticated requests are performed by the CLI with bounded,
  no-redirect transport and no implicit write retries;
- every write performs a fresh Prime compatibility/capability/authorization
  check internally;
- the engine advertises enough operation semantics that the CLI does not inspect
  engine source or guess routes;
- omitted post status creates a draft and publication requires explicit intent;
- destructive commands require resource-specific confirmation;
- create operations are idempotent or clearly return an unknown outcome that is
  not retried;
- engine and CLI errors can be handled using stable codes;
- writes include request identity and useful safe links;
- stale updates cannot silently overwrite concurrent edits;
- skill, CLI, operation-contract, and API-major skew is detectable; and
- setup credentials do not need to pass through an agent conversation.
