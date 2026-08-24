# RailsPress Agent CLI and API Onboarding

Status: research and recommendations only  
Date: 2026-08-24  
Repositories reviewed:

- `railspress-engine/railspress`
- `railspress-agent` at `/Users/avi/Development/code/RailsPress/railspress-agent`

## Executive summary

The current **Agents & API** screen exposes too much of the implementation model before it explains the task the user is trying to complete. Installation is presented as seven commands, the project manifest appears without enough context, and bootstrap onboarding is split into separate `config check`, `config trust`, environment-variable, stdin, and `onboard` steps.

The normal path should feel like this:

1. Install RailsPress Agent with one conventional shell command.
2. Create a one-time Agent Setup Key.
3. Give the generated setup instructions to the coding agent from the publishing project.
4. Let RailsPress Agent validate prerequisites, create or validate project configuration, request trust when necessary, exchange the setup key, store the resulting API key, and verify the connection.

Advanced concepts should remain available, but they should not dominate the default UI.

RailsPress Agent is currently **both** a CLI and an agent-skill distribution:

- The CLI owns installation/update/rollback/uninstall, diagnostics, project configuration validation and trust, bootstrap exchange, secure token storage, and `/prime` capability discovery.
- The Codex and Claude adapters install a `railspress` skill that teaches the coding agent discovery, safety rules, API behavior, content formats, media, imports, taxonomies, and error handling.
- The CLI does **not** currently own content CRUD, media, taxonomy, or import commands. After running CLI `prime`, the skill still directs the coding agent to call the RailsPress HTTP API itself.

That hybrid architecture is sensible for v1, but the admin page should name it clearly. “Install RailsPress Agent” currently sounds like a CLI-only installation even though the default installer detects Codex and/or Claude and installs their RailsPress skills too.

## What exists today

### Engine-generated screen

`Agents & API` currently contains four concepts on one page:

1. Install and verify RailsPress Agent.
2. Copy a token-free `RAILSPRESS.md` manifest.
3. Copy generic bootstrap quick-start and agent instructions.
4. Manage API keys and agent bootstrap keys.

The generated installation block is:

```sh
ruby --version  # Ruby 3.3+
curl --version  # curl 8.4+
curl --proto '=https' --tlsv1.2 -fsS -o railspress-install.sh https://agent.railspress.org/install.sh
less railspress-install.sh
sh railspress-install.sh --all
"$HOME/.railspress/bin/railspress-agent" version
"$HOME/.railspress/bin/railspress-agent" doctor
```

The installer already checks the operating system, architecture, `HOME`, Ruby version and standard library, curl version, tar, filesystem ownership, archive checksums, release URL, and adapter selection. Requiring users to preflight Ruby and curl duplicates the installer. Downloading, reading, and separately executing the script is a useful advanced security option, not the appropriate default quick start.

The public installer also already auto-detects installed Codex and Claude runtimes when no adapter flag is supplied. `--all` is therefore unnecessary in the normal command and can create irrelevant adapters for runtimes the user does not use.

### Project manifest

The generated `RAILSPRESS.md` is not a credential and is not an instruction file in the usual sense. It is a committed, project-scoped connection descriptor:

```yaml
---
railspress:
  host: http://127.0.0.1:3111
  api_base: http://127.0.0.1:3111/railspress/api/v1
  token_file: $HOME/.railspress/tokens/127.0.0.1-3111
---
```

Its purpose is to answer three questions deterministically when an agent is running inside a project:

- Which RailsPress site does this project publish to?
- Where is that site's mounted API?
- Which external credential file belongs to that site?

This matters when a developer has several repositories or RailsPress sites. It prevents an agent from guessing a host, scanning token files, or sending a credential to the wrong server. A separate local trust binding pins those three values so a repository change cannot silently redirect an existing credential.

The model is defensible, but the current UI makes the user manually understand and assemble an internal security boundary. The prose below the YAML does not explain why the file exists, why it belongs in the publishing project rather than the Rails host project, or why `config trust` is separate from YAML validation.

There are also three pieces of state for one connection:

| State | Location | Secret? | Purpose |
| --- | --- | ---: | --- |
| Project connection | `<project>/RAILSPRESS.md` | No | Selects host, API mount, and credential path |
| Trust binding | `~/.railspress/bindings/` | No | Records explicit local approval of that mapping |
| API credential | `~/.railspress/tokens/<site>` | Yes | Authenticates normal API requests |

This is useful developer documentation, but it is too much conceptual load for the primary setup card.

### CLI and skills boundary

The current CLI exposes:

- `version`, `doctor`
- adapter installation and lifecycle commands
- `config check`, `config trust`
- `onboard`
- `prime`
- `token store`

The installed Codex and Claude skills contain the actual publishing protocol. They tell the agent to discover `RAILSPRESS.md`, establish trust, run `prime` before writes, use returned capabilities and resolved endpoints, default to drafts, and safely call content/media/import/taxonomy endpoints.

This means the current product is best described as:

> RailsPress Agent installs a secure local CLI and a RailsPress skill for your coding agent. The CLI manages setup and credentials; the skill teaches the agent how to publish through the API.

The screen should say this directly.

## Bootstrap keys versus API keys

The UI should consistently use **key** rather than switching between “key” and “token” except when describing the literal bearer token value.

| | Agent Setup Key (bootstrap key) | API Key |
| --- | --- | --- |
| Prefix | `rpb_...` | `rp_...` |
| Purpose | First-time onboarding only | Normal authenticated API access |
| Lifetime | Short-lived and one-time use | Long-lived or administrator-selected expiry |
| Can call content endpoints? | No | Yes |
| Stored locally? | No; keep transient | Yes, outside the repository |
| What happens when used? | Exchanged once for a new API key | Sent as bearer authentication |
| Best use | Give an agent permission to set itself up without revealing a reusable credential | Direct integrations, CI, custom clients, or manual setup |
| If exposed | Revoke before it is exchanged | Revoke or rotate immediately |

Recommended product language:

- Rename the user-facing **Agent Bootstrap Key** action to **New Agent Setup Key**.
- Retain “bootstrap key” in technical help and API documentation.
- Describe it as: “A short-lived, one-time key that lets RailsPress Agent create and securely store its own API key. It cannot publish content.”
- Describe an API key as: “A reusable bearer credential for the RailsPress API. Use this for custom integrations or when you are not using RailsPress Agent onboarding.”

The default agent path should use a bootstrap key. A user should create a direct API key only when they know they need a reusable credential: for example a custom script, CI secret, third-party client, or manual legacy flow.

## Recommended screen structure

Rename the page to **Agents & API** only if direct API management remains equally important. If agent use is the primary task, **Connect an Agent** is clearer, with API keys in a secondary **Developer API Keys** section.

### 1. Connect your coding agent (recommended)

Lead with one sentence explaining the installed components:

> Install the RailsPress CLI and the RailsPress skill for detected coding agents. The installer checks requirements and configures the supported agents it finds.

Show one primary command:

```sh
curl -fsSL https://agent.railspress.org/install.sh | sh
```

This matches common installation conventions and leaves prerequisite checks to the installer. The fully constrained download form and inspect-first form should remain in an expandable **Security and advanced install options** section and in the agent repository documentation.

There is a real security tradeoff: the short command relies on curl's normal HTTPS behavior for delivery of the installer itself, while the current explicit flags constrain protocol and TLS version. The downloaded installer can validate the environment and all subsequent release downloads, but it cannot retroactively secure its own download. That tradeoff is reasonable for the primary convenience path if the advanced inspect/pinned/checksum guidance remains available.

Do not put `version` and `doctor` in the copyable primary install block. A successful installer should print its own concise success state and next action. Put `railspress-agent doctor` under **Troubleshooting**.

If the PATH update is optional or declined, the installer may still need to print the absolute command path. The admin page should prefer `railspress-agent` in examples and explain once that `~/.railspress/bin/railspress-agent` works before restarting the shell.

### 2. Set up this project

The current flow requires users to copy a manifest, understand a publishing-project placeholder, run a check, run trust, and then onboard. This should become one coherent setup action.

The ideal CLI addition is a high-level command such as:

```text
railspress-agent connect
```

Run from the publishing project, it should:

1. Accept or discover the admin-generated non-secret connection descriptor.
2. Create or validate `RAILSPRESS.md` with an explicit preview.
3. Display the normalized host, API base, and credential destination.
4. Ask for local trust approval when interactive.
5. Read an Agent Setup Key from a hidden prompt or stdin.
6. Exchange it exactly once, store only the API key, and verify `/prime`.
7. Report which coding-agent skills are installed and that the project is ready.

This should compose the existing validation, trust, onboarding, and prime primitives rather than weaken them. `config check`, `config trust`, and `onboard` should remain stable lower-level commands for automation and diagnosis.

Until that command exists, the screen can still substantially improve the flow:

- Say **Run these instructions from the project that contains the content you want the agent to publish**, not `/path/to/publishing-project` without explanation.
- Present the manifest as **Project connection file**, with a two-sentence explanation and a copy button.
- Hide raw `config check` and `config trust` commands under **What RailsPress Agent will verify**. They are internal steps for a coding agent, not useful top-level actions for most people.
- Generate one complete **Copy setup instructions for your agent** block after an Agent Setup Key is created. It can instruct the coding agent to create `RAILSPRESS.md`, show the connection values for approval, establish trust, and run `onboard`.
- Do not show a generic `<YOUR_BOOTSTRAP_TOKEN>` block before a key exists. Its incompleteness looks like a runnable quick start but cannot succeed.

### 3. Use RailsPress without the CLI

Keep the original agent-driven API protocol as a clearly labeled fallback:

> **Manual agent setup (without the RailsPress CLI)**  
> Use this only when the CLI cannot be installed. Your coding agent will validate project configuration, exchange or load credentials, call `/prime`, and use the HTTP API directly.

This mode should provide agent-oriented instructions, not a wall of shell commands. It needs:

- host and mounted API base;
- the bootstrap exchange endpoint;
- the one-time Agent Setup Key, or a direct API key when the user explicitly chose that route;
- the expected `/prime` behavior;
- draft-by-default and explicit-publish rules;
- capability and endpoint discovery rules;
- no-redirect and credential-handling rules;
- error and unknown-outcome handling.

The earlier skill already encoded most of this protocol. It can be retained as a **manual/no-CLI reference** rather than replaced by CLI-only instructions. Care is needed around partial bootstrap failures: the high-level CLI intentionally avoids retries and exposes milestones; a hand-rolled agent flow must preserve the minted API key in-process if exchange succeeds but local storage fails, or revoke it if recovery is impossible.

This section should be collapsed by default. The recommended CLI installation also installs the project skill, so “with CLI” and “without CLI” are not two different skill products; they are two execution strategies for the same publishing protocol.

### 4. Developer API keys

Move direct API keys after agent onboarding and label their audience:

> Create a reusable API key for custom scripts, CI, or clients that do not use Agent Setup Keys.

The reveal page can offer two tabs:

- **Use with RailsPress Agent**: securely store the direct key, then run `prime`.
- **Use the HTTP API directly**: bearer-authentication example plus a link to API documentation.

Avoid presenting direct API keys and setup keys as interchangeable ways to perform the same step. They have different exposure, lifetime, storage, and recovery properties.

## Proposed default copy

### Install card

> **Install RailsPress Agent**  
> Installs the RailsPress CLI and the RailsPress skill for Codex and Claude when detected. The installer checks system requirements automatically.

```sh
curl -fsSL https://agent.railspress.org/install.sh | sh
```

Secondary links: **Advanced installation**, **What gets installed?**, **Troubleshooting**.

### Project connection explanation

> **Connect this publishing project**  
> `RAILSPRESS.md` tells your coding agent which RailsPress site this project publishes to. It contains no credentials and is safe to commit. RailsPress stores the API key separately in your home directory.

The page should explicitly name the expected destination, for example:

> Save this as `RAILSPRESS.md` in the root of the project whose content the agent will publish. This may be different from the Rails application hosting RailsPress.

### Agent Setup Key explanation

> **Create an Agent Setup Key**  
> This one-time key lets RailsPress Agent finish setup and create a reusable API key. It expires in one hour, cannot publish content itself, and is never saved to the project.

### Direct API key explanation

> **Create a Developer API Key**  
> Use a reusable API key for custom scripts, CI, or direct HTTP API access. If you are connecting Codex or Claude for the first time, use an Agent Setup Key instead.

## Recommendations for the `railspress-agent` repository

### High priority

1. Add a high-level interactive `connect` or `setup` command that composes manifest creation, trust approval, bootstrap input, onboarding, and prime. Preserve the existing low-level commands.
2. Make installation success output answer: what was installed, which adapters were enabled, whether PATH is active, and the single next action.
3. Add a concise `capabilities` or `doctor --project` presentation for humans. Current `prime --json` is appropriate for agents, while onboarding UI needs a readable success summary.
4. Preserve both the CLI-assisted skill workflow and the manual/no-CLI protocol in documentation. Label the latter as fallback compatibility rather than “original version.”
5. Make the CLI/skill ownership boundary explicit in README and help: setup and capability discovery are CLI-owned; content requests are currently skill/API-owned.

### Medium priority

1. Consider moving content operations behind CLI subcommands over time (`posts create`, `posts update`, imports, assets). This would keep credentials entirely inside the CLI instead of requiring the skill to read the managed token for writes.
2. If content commands are not planned for v1, expose a narrowly scoped authenticated request helper that accepts method, a `/prime`-resolved endpoint name, and payload over stdin. This reduces credential handling in generated shell while preserving capability checks.
3. Add a machine-readable installation result or `doctor --json` field listing installed adapters and skill paths so the engine's instructions can diagnose “CLI installed but skill missing.”
4. Add an explicit no-CLI documentation page assembled from the manual protocol. The repository currently documents the manual mechanics across the skill, `agent-protocol.md`, `credentials.md`, and `bootstrap.md`, but does not present them as one supported fallback journey.

## Suggested implementation sequence

1. Simplify only the admin-page copy and installation command; no agent CLI behavior is required for this first improvement.
2. Reorganize the page into recommended agent setup, manual/no-CLI fallback, and developer API keys.
3. Rename user-facing bootstrap terminology to Agent Setup Key while preserving API/model names.
4. Add the high-level CLI `connect` command.
5. Replace the manifest/check/trust/onboard command wall with the new command once released, while keeping advanced details accessible.
6. Later decide whether the CLI should own content writes or remain a secure setup/prime boundary paired with an agent skill.

## Decision summary

- Yes, the installation instructions are unnecessarily cumbersome for the primary UI. Use one conventional command and let the installer report prerequisite failures.
- `RAILSPRESS.md` still serves a valid project-to-site selection and credential-binding purpose, but the screen currently explains it poorly and asks users to operate at too low a level.
- The separate `config check` and `config trust` operations are security primitives, not a good primary onboarding experience. A high-level interactive command should compose them while retaining explicit approval.
- RailsPress Agent includes both the CLI and the Codex/Claude skills. It is not CLI-only.
- The skill is still essential because the CLI currently stops at setup and `/prime`; publishing continues through agent-authored HTTP API calls.
- The UI should recommend Agent Setup Keys for first-time agent onboarding and direct API keys for reusable/custom integrations.
- The legacy no-CLI agent protocol should remain documented and available, but collapsed and clearly labeled as an advanced fallback.
