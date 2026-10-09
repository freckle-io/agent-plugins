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
Install the Freckle plugin for Claude Code for me. Run each step in your shell, skip any step that is already done, and tell me what you did.

1. Find a `claude` binary: use `claude` if it is on PATH. Otherwise, on a Mac, use the newest Claude Desktop copy: `ls -d "$HOME/Library/Application Support/Claude/claude-code/"*/*/claude.app/Contents/MacOS/claude | sort -V | tail -1`. Call it CLAUDE below and quote its path.
2. If `CLAUDE plugin marketplace list` does not show `freckle-plugins`, run `CLAUDE plugin marketplace add freckle-io/agent-plugins`.
3. If `CLAUDE plugin list` does not show `freckle@freckle-plugins`, run `CLAUDE plugin install freckle@freckle-plugins`.
4. Turn on auto-update for this marketplace only: in `~/.claude/settings.json`, set `extraKnownMarketplaces["freckle-plugins"].autoUpdate` to `true`, keeping every other key and value exactly as it is (create the file or keys if missing; keep the existing `source` if there is one). Do not set `FORCE_AUTOUPDATE_PLUGINS` or change any other marketplace.
5. Run `CLAUDE plugin list` and confirm `freckle@freckle-plugins` is enabled. Then, if the Freckle setup skill is now available in this chat, run it now to sign me in to Freckle. If it isn't, tell me to start a new chat (or restart `claude` in the terminal) and send: "Run the Freckle plugin setup skill and help me sign in to Freckle."

If any step fails, tell me the error and walk me through the manual install instead: run `/plugin marketplace add freckle-io/agent-plugins`, then `/plugin install freckle@freckle-plugins`, then in `/plugin` → Marketplaces → freckle-plugins choose "Enable auto-update".
````

The plugin enables auto-update for the `freckle-plugins` marketplace at session
start and preserves an explicit opt-out. It does not change auto-update for any
other marketplace. As a fallback, use `/plugin` → **Marketplaces** →
`freckle-plugins` → **Enable auto-update**.

Existing installs from before this hook shipped need a one-time update to
receive it: run `/plugin marketplace update freckle-plugins`, then
`/plugin update freckle@freckle-plugins`, and start a new session.

**Codex:**

Copy and paste this prompt into a new Codex chat. If you are the agent, carry
out its steps yourself:

````text
Install the Freckle plugin for Codex for me. Run each step in your shell, skip any step that is already done, and tell me what you did.

1. If `codex plugin marketplace list` does not show `freckle-plugins`, run `codex plugin marketplace add freckle-io/agent-plugins`. If it is already there, run `codex plugin marketplace upgrade freckle-plugins` to get the latest version.
2. If `codex plugin list` does not show `freckle@freckle-plugins` as installed, run `codex plugin add freckle@freckle-plugins`.
3. Run `codex plugin list` and confirm `freckle@freckle-plugins` is installed and enabled. Then, if the Freckle setup skill is now available in this chat, run it now to sign me in to Freckle. If it isn't, tell me to start a new chat (or restart `codex`) and send: "Run the Freckle plugin setup skill and help me sign in to Freckle."

If any step fails, tell me the error and walk me through the manual install instead: in the Codex app, open Plugins → Add → Add a marketplace, paste https://github.com/freckle-io/agent-plugins.git, then in the Personal tab click Add on Freckle.
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

1. Check state: `freckle auth status; echo "exit_code=$?"`
2. If `freckle` is not found, use the bundled launcher at `bin/freckle` inside
   the installed plugin directory (it downloads and checksum-verifies the real
   CLI on first use), and put it on PATH per the setup skill.
3. Sign in with `freckle auth` — a device flow that opens the user's browser
   and prints a one-time code. Show the user the code and tell them to approve
   it in the browser. Confirm with `freckle auth status`.

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
