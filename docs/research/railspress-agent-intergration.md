---
title: RailsPress Agent integration audit
type: research
status: complete
date: 2026-08-22
engine_version: 1.4.5
engine_commit: fb637571bd3a17d937c229d4ffa6fe752b92cc98
agent_version: 0.1.2
agent_commit: d4c59185563a25f4e71b29ff0ca15a4595e6fa3e
---

# RailsPress Agent Integration Audit

## Executive summary

RailsPress Engine 1.4.5 and RailsPress Agent 0.1.2 are API-compatible at the
audited commits. The agent's fast suite, pinned source contract, and opt-in live
bootstrap-to-`/prime` test all pass against this engine checkout. The public
0.1.2 release, installer domain, release assets, and clean release-mode
install/doctor/uninstall lifecycle also passed this audit.

The engine does **not yet fully support the agent's intended onboarding
workflow**, however. The engine's Agents & API page still presents hand-written
shell and `curl` instructions. It neither offers RailsPress Agent as a visible
installation choice nor emits the required non-secret `RAILSPRESS.md` project
manifest. Its storage examples bypass the CLI's hardened token writer. A user
can make the two repositories work together today, but only by learning the
agent repository's configuration model and manually bridging the gap.

There is also an important product-scope distinction:

- The current `railspress-agent` CLI manages installation, adapters, project
  trust, token storage, upgrades, rollback, and uninstall.
- It is **not** currently a RailsPress API client. It cannot exchange a
  bootstrap key, call `/prime`, create or update a post, upload media, import,
  publish, or delete content.

Consequently, “agents should use the CLI” is achievable immediately for
installation, configuration validation, trust, token persistence, and
diagnostics. Making all API activity CLI-driven requires new agent CLI commands.
The engine should not document nonexistent CLI publishing behavior.

## Audit scope and evidence

This audit compared:

- RailsPress Engine `1.4.5` at
  `fb637571bd3a17d937c229d4ffa6fe752b92cc98`;
- RailsPress Agent `0.1.2` at
  `d4c59185563a25f4e71b29ff0ca15a4595e6fa3e`;
- the public `v0.1.2` GitHub release published on 2026-08-23 UTC;
- `https://agent.railspress.org/install.sh`; and
- the engine API, admin instruction builders, request specs, agent CLI,
  installer, adapters, documentation, tests, and release workflows.

Commands exercised during the audit:

```text
railspress-agent --version
railspress-agent help
bundle exec rake test:fast
bundle exec rake test:contract
RAILSPRESS_LIVE_ENGINE=1 ... bundle exec rake test:live
RAILSPRESS_PUBLIC_PROBE=1 scripts/check-public-installer
public 0.1.2 clean-home install -> version -> doctor --json -> uninstall
```

Results:

| Check | Result |
| --- | --- |
| Agent fast suite | 158 runs, 1,991 assertions, 0 failures |
| Pinned engine source contract | 5 runs, 54 assertions, 0 failures, live case skipped as expected |
| Opt-in live engine flow | 1 run, 14 assertions, 0 failures |
| Public installer domain | Direct installer bytes and required headers match the reviewed repository |
| GitHub release | `v0.1.2` is public, non-prerelease, and contains all five expected assets |
| Release workflow | Successful for `v0.1.2` |
| Clean public lifecycle | Install, version, doctor, and uninstall passed with an explicit Ruby toolchain path |

The clean-home test initially failed before the installer ran because the local
Ruby executable was supplied by a HOME-dependent mise setup. With a temporary
HOME, mise could not trust its normal configuration and therefore exposed no
Ruby version. Repeating with the Ruby installation directory explicitly on
`PATH` passed. This is not an installer defect, but the installation guide
should tell users to run `ruby --version` in the exact shell/session that will
run the installer.

## Compatibility verdict

### What is compatible now

| Boundary | Verdict | Notes |
| --- | --- | --- |
| Ruby/platform baseline | Compatible | Both projects require Ruby 3.3+. Agent release mode supports macOS and Linux; native Windows is not supported. |
| Authentication | Compatible | Engine API keys and one-time bootstrap keys match the agent's token-shape and lifecycle expectations. |
| Bootstrap exchange | Compatible at API level | Engine returns `201` and `data.api_key.token`; the agent live test verifies this. The CLI has no exchange command. |
| `/prime` handshake | Compatible | Version, defaults, capabilities, endpoint inventory, and key metadata match the pinned agent contract. |
| Draft safety | Compatible | Engine defaults to draft and advertises explicit publishing; agent instructions preserve that behavior. |
| Content formats | Compatible | HTML, Markdown, plain text, and `auto` match the agent protocol. Reads remain canonical HTML. |
| Imports/media/taxonomy | Compatible | The advertised capability and endpoint shapes match the current agent audit fixture. |
| Custom engine mounts | Compatible when manifest is correct | Agent resolves `/prime` endpoints against `host` rather than assuming `/railspress`. |
| Token scope | Compatible | Agent consumes the engine-generated site-scoped path rather than reimplementing its derivation. |
| Adapter installation | Compatible | Public installer supports Codex, Claude, all detected adapters, or core-only installation. |
| Independent release cadence | Compatible | Agent uses Ruby standard library at runtime and does not need the engine gem installed locally. |

### What prevents “full support” today

1. The engine does not generate or prominently explain `RAILSPRESS.md`.
2. The engine does not link to or offer the RailsPress Agent installer.
3. Engine-generated setup instructions use direct shell writes instead of
   `railspress-agent token store`.
4. The copied instructions do not run `config check`/`config trust` before a
   credential is read or sent.
5. Bootstrap exchange and API requests still require `curl` because the CLI has
   no API commands.
6. The generic Agents & API page can reconstruct and redisplay the newest active
   bootstrap secret after its original reveal, conflicting with the one-time
   reveal model.

The compatibility verdict is therefore:

> Compatible API and release foundations; incomplete engine onboarding and
> incomplete CLI ownership of the runtime API workflow.

## CLI audit

### Current public command surface

The implemented CLI exposes:

```text
version
help [COMMAND]
install codex|claude|all
migrate-source-install codex|claude|all
doctor [--start DIR] [--json]
update [--version VERSION]
rollback [VERSION]
uninstall [codex|claude|all]
config check [--start DIR]
config trust [--start DIR] [--replace]
token store TOKEN_FILE
```

This is a strong lifecycle/configuration CLI. Particularly good properties are:

- release assets are checksum-validated before extraction;
- installation is versioned and supports rollback;
- source and release installs have explicit migration behavior;
- install/update/uninstall preserve tokens and trust bindings;
- `token store` reads the secret from standard input, validates the destination,
  and avoids a token command-line argument;
- project trust binds `host`, `api_base`, and `token_file` before a bearer token
  can be read;
- authenticated redirect-following is prohibited by the installed protocol;
- installation requires no Bundler after installation;
- install setup is consent-aware and does not require `sudo`; and
- release CI tests deterministic artifacts on Ubuntu and macOS.

### CLI gaps and issues

#### High: it is not an API client

There is no command for bootstrap exchange, `/prime`, posts, assets, imports,
categories, or tags. The installed skill must implement the actual API calls
itself with `curl`. This makes “use the CLI” true only for the setup boundary.

Suggested minimum API-client increment:

```text
railspress-agent onboard [--start DIR]
railspress-agent prime [--start DIR] [--json]
```

`onboard` should read the bootstrap token from standard input, validate project
trust, exchange without redirects, atomically store only the returned API key,
clear secret references, and verify `/prime`. This one command would remove the
most security-sensitive hand-written shell sequence from engine instructions.

After that, add domain commands only if the product goal is genuinely a
publishing CLI:

```text
railspress-agent posts list|show|create|update|delete
railspress-agent imports create|show
railspress-agent assets upload
railspress-agent categories ...
railspress-agent tags ...
```

Prefer file/stdin JSON or explicit non-secret flags. Never accept bearer or
bootstrap tokens as arguments. Every mutating command should internally call
`/prime`, use advertised paths/capabilities, default to draft, and require an
explicit publish/delete switch.

#### Medium: `help [COMMAND]` is advertised but not implemented

`railspress-agent help install` prints the same global usage as
`railspress-agent help`. Either implement per-command help with examples and
exit behavior or change the usage line to advertise only `help`.

#### Medium: `doctor` combines installation and optional project state

This is useful, but engine documentation should be precise about the two
doctors:

- `railspress-agent doctor --start ...` checks the agent installation and, when
  discoverable, project configuration/trust.
- `bin/rails railspress:doctor` checks the host application's engine setup.

They are complementary and should be shown together in troubleshooting, not
presented as substitutes.

#### Easy win: add an explicit prerequisite probe

Installation docs list requirements, but the top-level happy path should begin
with:

```sh
ruby --version # must be 3.3+
curl --version # must be 8.4+
```

This is especially helpful for version-manager shells and automation.

## Engine onboarding and documentation audit

### Critical: no `RAILSPRESS.md` bridge

RailsPress Agent treats the nearest valid `RAILSPRESS.md` as the only
project-specific source for:

- `railspress.host`;
- `railspress.api_base`; and
- `railspress.token_file`.

The engine already computes all three values for its copied instructions, but
it does not render a manifest block or provide a copy/download action. Without
the manifest, `config check`, `config trust`, and returning-agent discovery
cannot complete. The user is expected to find the separate agent template and
translate engine instructions manually.

Recommended engine addition: render a **Project manifest** card on Agents & API
with a copyable, token-free block:

```markdown
---
railspress:
  host: https://blog.example.com
  api_base: https://blog.example.com/railspress/api/v1
  token_file: $HOME/.railspress/tokens/blog.example.com
---

# RailsPress

This project publishes through RailsPress. Its API token is stored outside
this repository at the path above.
```

This card belongs outside secret reveal instructions because the manifest is
safe to commit and useful before a key exists. Label it clearly: “Save as
`RAILSPRESS.md` at your publishing project root; review and commit this file.”
Do not put any token in it.

### High: RailsPress Agent is absent from the Agents & API page

Add an always-visible **Recommended agent setup** section above the generic
bootstrap snippets. It should remain visible even when no bootstrap key exists
and should not be embedded only inside the copied AI prompt.

Recommended content:

1. Requirements: macOS/Linux, Ruby 3.3+, curl 8.4+, `tar`.
2. Review-first installer as the primary security-conscious example.
3. One-line installer as the compact alternative.
4. Adapter selection examples (`--codex`, `--claude`, `--all`).
5. Verification with `railspress-agent version` and
   `railspress-agent doctor`.
6. A link to the public agent repository/install guide.
7. The generated `RAILSPRESS.md` block.
8. The next step: create a short-lived Agent Key and use the CLI-driven
   onboarding path when it exists.

Suggested visible install copy:

```sh
curl --proto '=https' --tlsv1.2 -fsS \
  -o railspress-install.sh \
  https://agent.railspress.org/install.sh
less railspress-install.sh
sh railspress-install.sh
railspress-agent version
```

The shorter pipe form can be shown as an alternative. The review-first form
better fits an admin/security page and reports download versus execution
failures more clearly.

### High: current token storage examples bypass the CLI

Both admin instruction controllers currently use:

```sh
install -d -m 700 "$(dirname "$RAILSPRESS_TOKEN_FILE")"
printf '%s\n' "$RAILSPRESS_TOKEN" > "$RAILSPRESS_TOKEN_FILE"
chmod 600 "$RAILSPRESS_TOKEN_FILE"
```

That bypasses the agent's ownership, symlink, hard-link, path containment,
atomic-write, and input validation checks. Once RailsPress Agent is offered,
the preferred example should be:

```sh
printf '%s\n' "$RAILSPRESS_TOKEN" \
  | railspress-agent token store "$RAILSPRESS_TOKEN_FILE"
```

Keep a clearly labeled manual fallback only for users who intentionally do not
install RailsPress Agent. Do not describe the direct shell write as equivalent
in safety.

### High: trust is missing from generated instructions

Before an installed agent reads or sends a bearer credential, the protocol
requires a matching owner-only trust binding. The engine snippets should guide
the user through:

```sh
railspress-agent config check --start /path/to/publishing-project
railspress-agent config trust --start /path/to/publishing-project
```

`config trust` must be framed as an explicit review/approval step. Generated
instructions must never include `--replace`; changed host/API/token paths need
separate approval.

### High: generic page redisplays a bootstrap secret

`ApiKeysController#latest_active_bootstrap_token` rebuilds the newest active
bootstrap token from encrypted state and inserts it into the generic Agents &
API page. This contradicts the reveal page's “will not be shown again” model
and expands secret exposure to every later index render.

Recommended change:

- stop reconstructing a plaintext bootstrap token on the index page;
- show `<YOUR_BOOTSTRAP_TOKEN>` in generic instructions;
- display a real bootstrap token only on its dedicated one-time reveal page;
- put the manifest/install cards on the index because they contain no secret;
  and
- add a request spec proving the index cannot contain a token-shaped bootstrap
  value after creation.

### Medium: generated `curl` is not failure-safe enough

The exchange snippets use `curl -s` in command substitution. A JSON error,
HTML interception page, or network failure can become an empty/invalid
`RAILSPRESS_TOKEN`, after which subsequent storage and verification steps are
hard to interpret. The snippets also duplicate security-sensitive parsing.

The preferred fix is a manifest-aware CLI `onboard` command. Until that ships,
the manual fallback should use `--fail-with-body --silent --show-error`, capture
the response/status separately, require `201`, validate
`data.api_key.token`, and stop before storage on any mismatch. It must continue
to avoid redirects.

### Medium: engine top-level docs undersell the agent option

Add RailsPress Agent to both locations:

- README “Enabling Agents & API”: a short recommended-tool callout after API
  enablement and before raw authentication details.
- `docs/api/README.md`: an “Agent installation” section before the bootstrap
  quickstart, linking to the agent install guide and explaining the manifest.

Also update `docs/api/agent_bootstrap_keys.md` so the preferred path uses the
CLI and the raw `curl` exchange is explicitly the no-agent/manual path.

## Recommended product flow

The clean target experience is:

```text
Host enables RailsPress API
  -> opens Agents & API
  -> installs RailsPress Agent (visible, non-secret section)
  -> copies token-free RAILSPRESS.md into publishing project
  -> verifies CLI and project config
  -> explicitly approves project trust
  -> creates one-time Agent Key
  -> pipes bootstrap secret to `railspress-agent onboard`
  -> CLI exchanges, stores API token, and verifies /prime
  -> installed adapter handles future publishing with draft-safe behavior
```

Until `onboard` exists, replace that one step with a clearly labeled manual
exchange plus `railspress-agent token store`. Do not claim complete CLI
onboarding before the command ships.

## Cross-repository testing audit

### What already exists and is good

The agent repository already has the right ownership direction: as the API
consumer, it owns consumer contract tests against the engine.

- `test/integration/local_engine_contract_test.rb` validates the pinned engine
  version/commit, required `/prime` markers, routes, request-spec inventory, and
  non-idempotent import guidance.
- `test/integration/live_engine_flow_test.rb` boots the sibling dummy app with a
  temporary SQLite database and HOME, issues a real bootstrap key, exchanges
  it, stores a token, and calls authenticated `/prime`.
- `test/fixtures/engine_contract.json` records the audited engine version and
  commit.
- Release CI checks out that exact engine commit and makes the contract a hard
  release gate.

This is materially better than adding the agent repository as an engine
runtime dependency or Git submodule.

### Blind spot: the live flow bypasses the stable CLI

The live harness invokes `scripts/store-token` directly. It does not exercise:

- `bin/railspress-agent token store`;
- manifest generation/discovery;
- `config check` and `config trust`;
- the installed release artifact; or
- an adapter installed through the lifecycle CLI.

Change the live seam to create a temporary `RAILSPRESS.md`, invoke the stable
CLI for trust and token persistence, then call `/prime`. Once `onboard` exists,
the live test should invoke that command and remove its hand-built exchange.
Keep engine endpoint behavior in RSpec; the cross-repo test should cover only
the integration seam.

### Blind spot: scheduled compatibility retests the pinned commit

The scheduled agent workflow defaults to the same exact engine SHA recorded in
the fixture. That proves reproducibility but cannot discover drift on engine
main. Passing it weekly provides little information beyond the release gate.

Use two modes:

1. **Pinned release contract (required):** exact audited SHA; hard failure; used
   for agent releases.
2. **Moving compatibility canary (scheduled/advisory):** check out engine main,
   run semantic source/live contracts without requiring the exact SHA, and
   create a visible failure/issue when compatibility changes.

Do not silently skip an unavailable engine ref in the moving canary. A required
release job already correctly hard-fails when its pinned source is unavailable.

### Recommended engine-side testing pattern

Normal engine RSpec must remain self-contained and must not require a sibling
repository. Add local engine tests for the contract it owns:

- request specs for the visible install and manifest cards;
- exact assertions that manifest values respect `public_base_url`, custom
  ports, base paths, and engine mounts;
- a spec that manifest/instructions contain no API or bootstrap secret;
- a spec that the index never redisplays an active bootstrap plaintext;
- documentation contract assertions for the public installer URL and preferred
  CLI commands; and
- existing `/prime` and exchange request specs as the server contract.

For cross-repo verification, add either a manually dispatched engine workflow
or a reusable workflow that checks out a pinned RailsPress Agent tag and runs
its semantic/live contract with `RAILSPRESS_ENGINE_PATH` pointing at the engine
checkout. Keep it non-blocking until the interface stabilizes, then make it a
required release check for changes under these paths:

```text
app/controllers/railspress/api/
app/controllers/railspress/admin/*api*/*
app/controllers/railspress/admin/*agent*/*
config/routes.rb
docs/api/
```

Avoid:

- a Git submodule;
- a permanent sibling-checkout requirement in ordinary RSpec;
- copying the full engine request suite into the agent repo;
- a moving unpinned agent dependency in normal engine PR CI; or
- one shared fixture with ambiguous ownership.

The engine owns server response/request specs. The agent owns client tolerance
and end-to-end onboarding. Each release records the opposite repository's
audited immutable revision.

## Prioritized implementation plan

### P0: engine safety and truthful onboarding

1. Stop redisplaying reconstructed bootstrap plaintext on the index page.
2. Add a token-free, copyable `RAILSPRESS.md` card.
3. Add an always-visible RailsPress Agent install card outside copied agent
   instructions.
4. Prefer `railspress-agent token store`; retain manual shell storage only as a
   labeled fallback.
5. Add request/documentation specs for all four changes.

These are mostly engine-side docs/view/controller changes and are the highest
value release-adjacent wins.

### P1: first-class CLI onboarding

1. Add stdin-only `railspress-agent onboard --start DIR`.
2. Add manifest-aware `railspress-agent prime --start DIR --json`.
3. Move exchange response/status validation into the CLI.
4. Update engine reveal instructions to use `onboard` as the preferred path.
5. Update the agent live test to invoke the stable CLI end to end.

This provides a coherent security boundary without yet committing to a full
content-management CLI.

### P2: documentation and release coupling

1. Add the agent option to engine README and `docs/api/README.md`.
2. Separate “with RailsPress Agent” and “manual API” paths in bootstrap docs.
3. Add the moving engine-main compatibility canary in the agent repo.
4. Add an optional pinned-agent workflow in the engine repo.
5. Record tested engine/agent version pairs in both release checklists.

### P3: optional publishing CLI

Only if product direction requires all agent writes to use the CLI, add
capability-driven domain commands for posts, imports, media, and taxonomies.
Design their input/output as a stable machine interface first; installed skills
can then become thinner orchestration guidance instead of duplicating HTTP
details.

## Easy wins

- Add one install card and one manifest card to Agents & API.
- Link `https://agent.railspress.org/install.sh` and the agent installation
  guide from engine API docs.
- Replace direct token-file writes with `railspress-agent token store` in the
  preferred snippets.
- Remove `latest_active_bootstrap_token` from generic index rendering.
- Add `ruby --version` and `curl --version` prerequisite checks to the top-level
  install path.
- Fix or remove the misleading `help [COMMAND]` claim.
- Make the live cross-repo test call `bin/railspress-agent`, not its internal
  storage script.
- Change the scheduled compatibility job from pinned-only repetition to an
  engine-main canary while keeping releases pinned.

## Scope boundaries

This audit did not change engine runtime behavior, admin UI, the agent CLI, or
either repository's tests. It did not perform any API write against a deployed
RailsPress site or read real credentials. The public installer smoke used an
isolated temporary HOME and core-only install, then uninstalled the managed
application.

## Conventions

This research was informed by:

- `docs/conventions/integrations/ai.md`;
- `docs/conventions/integrations/external_apis.md`;
- `docs/conventions/operations/bin_scripts_and_tasks.md`;
- `docs/conventions/testing/rspec/overview.md`; and
- `docs/conventions/testing/rspec/isolation.md`.
