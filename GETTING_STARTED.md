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

```
/plugin marketplace add freckle-io/agent-plugins
/plugin install freckle@freckle-plugins
```

Or from a shell:

```bash
claude plugin marketplace add freckle-io/agent-plugins
claude plugin install freckle@freckle-plugins
```

**Codex:**

```bash
codex plugin marketplace add freckle-io/agent-plugins
```

Then in Codex, run `/plugins` and install **Freckle**.

If you can't install the plugin (no plugin support in this host, or policy
blocks it), fall back to the standalone installer, which installs the CLI and
agent skills directly:

```bash
sh -c "$(curl -fsSL https://install.freckle.io)"
```

## 2. Get `freckle` on PATH and sign in

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
