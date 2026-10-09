# Getting started with Freckle

This guide is written to be followed by an AI coding agent (Claude Code or
Codex) on a user's behalf. If you are that agent: work through it top to
bottom, running the commands yourself and asking the user only when a step
says to.

Freckle is an AI-powered lead enrichment platform. Everything goes through the
**`freckle` CLI**; the plugin in this repo ships the skills that teach you how
to drive it, a bundled launcher for the CLI itself, and permission hooks so
plain `freckle` commands don't prompt on every call.

## 1. Install the plugin

Identify which host you're running in and use its path. If the plugin is
already installed (its skills are visible), skip to step 2.

**Claude Code:**

Copy and paste this prompt into Claude Code (a new chat in the Claude app's
Code tab, or `claude` in a terminal). If you are the agent, carry out its steps
yourself:

````text
Install the Freckle plugin for Claude Code and sign me in to Freckle. Skip anything that's already done, and tell me what you did.

- Add the marketplace `freckle-io/agent-plugins` (it's named `freckle-plugins`) and install the plugin `freckle@freckle-plugins` with the `claude plugin` commands. If `claude` isn't on PATH, use the newest Claude Desktop copy under `~/Library/Application Support/Claude/claude-code/`.
- Turn on auto-update for this marketplace only: set `extraKnownMarketplaces["freckle-plugins"].autoUpdate` to `true` in `~/.claude/settings.json` and leave everything else in that file as it is. Don't set `FORCE_AUTOUPDATE_PLUGINS`.
- Sign me in: if the Freckle setup skill is available here, run it. Otherwise check `freckle whoami --json`, and if I'm not signed in, run `freckle login`, show me the code and wait while I approve it in the browser. If `freckle` isn't on PATH, use the plugin's copy at `~/.claude/plugins/cache/*/freckle/*/bin/freckle`.

If something fails, tell me the error and how to finish with `/plugin` instead.
````

**Codex:**

Copy and paste this prompt into a new Codex chat. If you are the agent, carry
out its steps yourself:

````text
Install the Freckle plugin for Codex and sign me in to Freckle. Skip anything that's already done, and tell me what you did.

- Add the marketplace `freckle-io/agent-plugins` (upgrade it if it's already there) and add the plugin `freckle@freckle-plugins` with the `codex plugin` commands.
- Sign me in: if the Freckle setup skill is available here, run it. Otherwise check `freckle whoami --json`, and if I'm not signed in, run `freckle login`, show me the code and wait while I approve it in the browser. If `freckle` isn't on PATH, use the plugin's copy at `~/.codex/plugins/cache/*/freckle/*/bin/freckle`.

If something fails, tell me the error and how to add it in the Codex app instead (Plugins → Add → Add a marketplace, then https://github.com/freckle-io/agent-plugins.git).
````

Codex has no background auto-update; to pick up new releases later, run the
prompt again (it upgrades the marketplace).

If you can't install the plugin (no plugin support in this host, or policy
blocks it), fall back to the standalone installer, which installs the CLI and
agent skills directly:

```bash
sh -c "$(curl -fsSL https://install.freckle.io)"
```

## 2. Get `freckle` on PATH and sign in

If an older standalone `freckle` shadows the plugin launcher, use the setup
skill below to repair PATH; plugin updates do not replace that standalone CLI.

Run the plugin's **`setup`** skill (`freckle:setup` in Claude Code). If you
can't invoke skills yet (for example, the plugin was installed this session),
do what it does:

1. Check state: `freckle whoami --json`. It exits 0 either way; `"status":
   "authenticated"` means signed in, `"not-authenticated"` means not.
2. If `freckle` is not found, use the bundled launcher at `bin/freckle` inside
   the installed plugin directory (it downloads and checksum-verifies the real
   CLI on first use), and put it on PATH per the setup skill.
3. Sign in with `freckle login` — a device flow that opens the user's browser
   and prints a one-time code. Show the user the code and tell them to approve
   it in the browser. Confirm `freckle whoami --json` reports `"status": "authenticated"`.

## 3. Pick the organization

Most commands are org-scoped:

```bash
freckle org list
```

If exactly one organization is available, use it without asking. Otherwise ask
the user to choose, then pin it in your shell for the rest of the session:

```bash
export FRECKLE_ORG_ID=<org-id>
```

Avoid `freckle org switch` — it writes shared global config that another agent
session can overwrite.

## 4. Do something

The **`freckle`** skill is the router for all Freckle work — load it and it
will direct you to the right reference for the request. Good first asks:

- *"Build a list of 50 Series B fintech companies and find each CEO's work
  email."*
- *"Enrich this CSV of domains with firmographics and score them against my
  ICP."*
- *"What can Freckle do?"*

The skill enforces the important guardrails on your behalf: it designs the
Workbook with the user before running anything, samples 10 rows first, and
returns a credit forecast before committing to a full run.
