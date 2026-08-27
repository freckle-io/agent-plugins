# Getting started with Freckle

This guide is written to be followed by an AI coding agent (Claude Code or
Codex) on a user's behalf. If you are that agent: work through it top to
bottom, running the commands yourself and asking the user only when a step
says to.

**What you're setting up.** Freckle is a GTM (go-to-market) lead-enrichment
tool built for GTM engineers — build lists of companies and people, enrich and
score them, and run saved workflows over whole datasets. The **`freckle` CLI**
is purpose-built to be driven by AI coding agents like you: everything goes
through it, its output is structured for you to read, and the skills it
installs teach you how to drive it. Installing it and signing the user in is a
normal, expected part of using Freckle.

## 1. Install the `freckle` CLI

**Claude Code (and any host without Freckle plugin support):**

Install the CLI and agent skills directly with the standalone installer:

```bash
sh -c "$(curl -fsSL https://install.freckle.io)"
```

This puts the `freckle` binary on PATH and installs the Freckle agent skills.
On native Windows 11 x64, use PowerShell instead:

```powershell
irm https://install.freckle.io/install.ps1 | iex
```

**Codex:**

Install the Freckle plugin (currently in testing on Codex):

```bash
codex plugin marketplace add freckle-io/agent-plugins
```

Then in Codex, run `/plugins` and install **Freckle**. The plugin ships the
skills, a bundled launcher for the CLI, and permission hooks so plain
`freckle` commands don't prompt on every call.

Codex has no background auto-update; to pick up new releases later, run
`codex plugin marketplace upgrade freckle-plugins`.

## 2. Get `freckle` on PATH and sign in

1. Check state: `freckle auth status; echo "exit_code=$?"`
2. If `freckle` is not found:
   - **Standalone install (Claude Code):** re-run the installer from step 1,
     then open a fresh shell or source your profile so the install location is
     on PATH.
   - **Codex plugin:** run the plugin's **`setup`** skill, or do what it does —
     use the bundled launcher at `bin/freckle` inside the installed plugin
     directory (it downloads and checksum-verifies the real CLI on first use)
     and put it on PATH per the setup skill.
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
