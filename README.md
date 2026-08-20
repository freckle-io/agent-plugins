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
