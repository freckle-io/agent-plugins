---
name: freckle
description: "Use when the user asks to use the Freckle CLI or get Freckle to do something: enrich/score/process a lead list, build a company or people list, import CRM records, monitor Dataset Signals, build or change Workbooks, datasets, or Workflows, publish or run saved workflows, inspect credit usage or node capabilities, auth/org/config setup, or integration connections."
---

# Freckle

This is a router skill: pick one primary route below and load adjunct references only when that route requires them. Load the route's file before running any `freckle` command — even `--help`; the route files tell you which commands to run and when.

**New builds are gated.** Route work with no existing target to [BUILD.md](BUILD.md). When the request identifies an existing Workbook or Workflow by URL, id, or name, route to [REFINE.md](REFINE.md) instead: locate the target, derive its org, and work from the design already embodied there. REFINE owns the fit test and escalates only a genuine redesign or a shape-changing ambiguity.

## Route

| User wants | Load |
| --- | --- |
| List building — build a new list of companies or people from a provider search, or run/inspect a List Workbook created by the `list` commands | [LIST.md](LIST.md) |
| Import a CSV or plain rows into a **new** Workbook, with no enrichment or workflow asked for and no existing target named | [BUILD.md#data-import-fast-lane](BUILD.md#data-import-fast-lane) — a pure import that names an existing Workbook or Dataset routes to [REFINE.md](REFINE.md) instead |
| Get Freckle to do something with no existing target — enrich, score, look up, run data, or build a Workbook or Workflow | [BUILD.md](BUILD.md) |
| Do anything to an existing Workbook or Workflow identified by URL, id, or name — add data, run rows, or change its setup | [REFINE.md](REFINE.md) |
| Run an existing saved Workflow directly with JSON inputs, inspect runs, list saved Workflows | [workflow/cli-reference.md](workflow/cli-reference.md) |
| Inspect node capabilities | [workflow/cli-reference.md#node-catalog](workflow/cli-reference.md#node-catalog) |
| Workbook housekeeping that changes nothing about what runs — inspect, archive, delete entries, rotate webhook secrets | [WORKBOOKS.md](WORKBOOKS.md) |
| Return a Dataset webhook endpoint URL | [WORKBOOKS.md](WORKBOOKS.md) |
| Create, inspect, list, turn monitoring on or off, or delete Dataset Signals | [SIGNALS.md](SIGNALS.md) |
| Check the current credit balance or report credit usage by Workbook, Workflow, or billed node | [CREDITS.md](CREDITS.md) |
| Log in, check auth, choose org, inspect endpoints | [SETUP.md](SETUP.md) |
| Connect Apify, ContactOut, HeyReach, HubSpot, Instantly, Salesforce, Slack, or Supabase, or find credential IDs | [CONNECTIONS.md](CONNECTIONS.md) |
| Set up, list, or pick a credential so Workflows can call an API with the user's own key — "use my own API key", "use tool X instead", any phrasing; a build or change request that mentions their own key still routes to BUILD or REFINE | [CONNECTIONS.md#custom-http-apis](CONNECTIONS.md#custom-http-apis) |
| Understand enrichment waterfalls, collectors, or Research Agent usage | [workflow/waterfall.md](workflow/waterfall.md), [workflow/collector.md](workflow/collector.md), [workflow/research-agent.md](workflow/research-agent.md) |
| Explain what Freckle can currently do — a capability question only, with no task attached | [WHAT-CAN-FRECKLE-DO.md](WHAT-CAN-FRECKLE-DO.md) |

## Shared Operating Rules

- When user decisions are needed, run a **batch grill**. Map the decisions as a design tree and work it in rounds. The frontier is every decision whose prerequisites are settled: ask the whole frontier in one round, number every question, and give your recommended answer for each, then wait for the user's answers. A decision that depends on another unsettled answer waits for a later round. After each reply, recompute the frontier. The grill is complete only when the frontier is empty: every shape-changing branch has been visited and nothing remains silently assumed. Make changes or run data only after the user confirms shared understanding; a route's later approval gate may supply that confirmation.
- Every question round and every plan opens with a **what-will-run summary**: two or three plain sentences saying what Freckle will do once the user says go — which rows it reads, what happens to each, where results land, and what it costs — in product words only, with no flag names, node keys, or field paths. The tables, diagrams, and commands that follow are evidence for the summary, never a substitute for it.
- Facts are agent work. Resolve anything available from the CLI, filesystem, inspected artifacts, catalogs, or other tools instead of asking the user. If a lookup can run independently, dispatch it and ask the rest of the frontier while it runs; only decisions downstream of that lookup wait.
- Names are agent work too. Choose the label for every new Workbook, Dataset, and Workflow yourself — short, descriptive, in the user's own words for the goal — and show it wherever the user meets the artifact: the what-will-run summary, the plan, and the final link. Use a name the user supplies verbatim; otherwise the user renames in the app if they prefer something else.
- Resolve the org from any named resource before asking the user. Confirm the active org only when the request supplies no resource from which to derive it. Auth-only, config-only, and generic product-capability answers need no org setup.
- After automatic resolution, user selection, or an explicitly supplied organization, append `--org-id=<org-id>` after the complete subcommand path of every subsequent CLI command — for example, `freckle workbook list --org-id=<org-id>` — preserving any organization the user supplied. Do not use `freckle org switch`; it writes shared global config that another agent can overwrite.
- Preflight before the first command: `command -v freckle && freckle auth status`.
- `--json` always means output: every command that prints a payload renders YAML by default and pretty JSON with `--json`. Inline JSON *input* is always `--input-json`, never `--json`.
- Confirm unfamiliar flags with `freckle <subcommand> --help` before running a command your route file prescribes.
- Use absolute `--file` paths when possible; package scripts can change relative resolution.
