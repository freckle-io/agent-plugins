<p align="center">
  <a href="https://freckle.io">
    <img src="./assets/freckle.png" alt="Freckle" height="72">
  </a>
</p>

<p align="center">
  <strong>Build with Freckle in your AI coding agent</strong> — skills and the <code>freckle</code>
  CLI, for Claude Code and Codex.
</p>

<p align="center">
  <a href="https://freckle.io">freckle.io</a> · <a href="./GETTING_STARTED.md">Getting started</a>
</p>

Freckle is an AI-powered lead enrichment platform — build lists of companies and
people, enrich and score them, and run saved workflows over whole datasets, all
from natural language. This repo is the plugin marketplace for `freckle`: one
plugin source, two coding-agent targets, sharing one set of skills and one CLI.

## Example

```
> Enrich this list of 200 domains with company size and industry, then score
  each against my ICP.

⏺ Workbook (Freckle) — created
  input Dataset · enrichment Workflow · output Dataset

⏺ Sample run — 10 rows
  acme.com      112 employees   B2B SaaS      ICP: 87
  northbeam.io   45 employees   Analytics     ICP: 74
  ... 8 more
  Credit forecast: ~2.1 credits/row · ~420 credits total. Continue?

⏺ Full run — 200/200 rows complete
```

No dashboard clicking, no manual list-building — your agent designs the
Workbook, gates the run on a sample and a credit forecast, then runs the rest.

## Set up

New here? Point your coding agent at **[`GETTING_STARTED.md`](./GETTING_STARTED.md)**
and ask it to set Freckle up for you. It walks through installing the plugin,
getting `freckle` on PATH, and signing in with `freckle auth`.

**If you're an agent reading this directly:** read
[`GETTING_STARTED.md`](./GETTING_STARTED.md) and follow it.

If your fetch/open mechanism fails on that link, returns empty content, or
can't read the GitHub blob page, fetch the raw file yourself instead:

```
curl -fsSL https://raw.githubusercontent.com/freckle-io/agent-plugins/main/GETTING_STARTED.md
```

### Claude Code

```
/plugin marketplace add freckle-io/agent-plugins
/plugin install freckle@freckle-plugins
```

### Codex

```bash
codex plugin marketplace add freckle-io/agent-plugins
```

Then open Codex, run `/plugins`, and install **Freckle**.

### After installing

Start a new session and ask your agent to *"set up Freckle"* — the plugin's
`setup` skill puts the bundled `freckle` CLI on your PATH (downloading a
checksum-verified binary on first use) and signs you in with `freckle auth`.

## What's inside

- **`freckle/skills/`** — agent skills: a router skill for all Freckle work
  (list building, Workbooks, Workflows, credits, connections) plus a `setup`
  skill for install and auth.
- **`freckle/bin/freckle`** — a small launcher that downloads the pinned,
  checksum-verified CLI release on first use and caches it.
- **`freckle/hooks/`** — permission hooks that auto-approve plain `freckle`
  CLI calls (credential flows still prompt), so the agent isn't interrupted on
  every command.

## Security model

This plugin downloads and runs a native binary, and it auto-approves some
agent tool calls. Here is exactly how each of those is constrained:

**The launcher only runs a release it can verify.** `freckle/bin/freckle`
downloads the CLI release pinned in `bin/cli-version` from
`https://releases.freckle.dev/cli/`, verifies the artifact against the
SHA-256 checksums committed in `bin/checksums.txt`, and refuses to run
anything that does not match. The verified binary is cached locally and
executed with auto-update disabled (`FRECKLE_CLI_AUTO_UPDATE=0`), so the
plugin can never silently swap binaries between releases — updating the CLI
means updating the plugin, where the new pin and checksums are visible in the
commit history. Both files are written only by the Freckle release pipeline.

**The command hook approves a narrow, parseable subset.**
`hooks/approve-cli.sh` auto-approves a Bash call only when it can fully parse
it as a plain `freckle` invocation: it tokenizes quote-aware, rejects any
command containing `&`, `<`, `>`, backticks, `$`, `\`, newlines, or more than
10k characters, and allows pipes only into a fixed list of read-only
formatters (`jq`, `grep`, `head`, `sort`, and similar). Sensitive subcommands
(`auth`, `connect`, `connection(s)`, `skills`, `update`, `org`) are never
auto-approved and always fall through to the normal permission prompt.
Anything the parser does not positively recognize is left for the user to
decide — the hook fails closed.

**The skills hook only approves the plugin's own surface.**
`hooks/approve-skills.sh` auto-approves invocations of this plugin's own
skills plus WebFetch/WebSearch, nothing else.

**Credentials stay in the CLI.** The plugin ships no secrets and stores none;
authentication happens through `freckle auth` in the CLI's own config, and
credential-touching commands always prompt (see above).

### Release automation

`freckle/skills/freckle/`, `freckle/bin/cli-version`, `freckle/bin/checksums.txt`,
and the `version` field in both plugin manifests are published automatically by
the Freckle CLI release pipeline on every CLI release — do not edit them by
hand; changes there would be overwritten by the next release. The plugin
version tracks the CLI as `<cli major.minor>.<release sequence>`.

## Standalone CLI install

Prefer the CLI without the plugin?

```bash
sh -c "$(curl -fsSL https://install.freckle.io)"
```

On native Windows 11 x64:

```powershell
irm https://install.freckle.io/install.ps1 | iex
```

---

<p align="center">
  <a href="https://freckle.io">Website</a> ·
  <a href="https://freckle.io/privacy-policy">Privacy policy</a> ·
  <a href="https://freckle.io/terms-of-service">Terms of service</a>
</p>
