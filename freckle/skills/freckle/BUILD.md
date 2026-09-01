# Build With Freckle

Freckle work lands in a **Workbook**: an input Dataset holding the user's rows, a Workflow wired to it, and an output Dataset collecting the newest result for each row. The Workflow is the reusable engine; the Workbook is what the user actually gets. When a user asks Freckle to do something, the destination is a Workbook unless they explicitly scope the request to a Workflow artifact — and even then, the path below still applies; the workbook parts simply fall away.

## Data-Import Fast Lane

If the request is **purely ingesting data into a new Workbook** — import a CSV or a set of rows, with no enrichment, scoring, workflow, or run asked for, and no existing Workbook or Dataset named as the destination — take this lane instead of the six-step path below. A pure import into an existing target is [REFINE.md](REFINE.md)'s work, not this lane's. Run the preflight and follow the shell-state rules from [SKILL.md#shared-operating-rules](SKILL.md#shared-operating-rules). If anything shape-changing is missing (destination workbook label, key column), ask for all of it in **one** batched round, with a recommended answer per question; ask nothing that the request or a lookup already answers.

Exact sequence for a CSV into a **new** Workbook:

```bash
freckle org list                          # exactly one org → use it silently; else ask in the same batched round
FRECKLE_ORG_ID=<org-id> freckle workbook create --label "<label>" --description "<one-liner>"
FRECKLE_ORG_ID=<org-id> freckle workbook dataset build new csv <workbook-id> /abs/path/rows.csv --label "<label>" --key-column <key>
FRECKLE_ORG_ID=<org-id> freckle workbook dataset entry list <workbook-id> <dataset-id> --limit 5   # verify rows landed
```

`build new csv` creates the Dataset and imports in one command, and deletes the Dataset again if the import fails. (Importing into an **existing** Dataset is [REFINE.md](REFINE.md) territory; the command it uses is `freckle workbook dataset csv import <workbook-id> <dataset-id> --file /abs/path/rows.csv --key-column <key>`.) Always pass a `--key-column` that uniquely identifies a row (re-imports then update instead of duplicating). Report the workbook id, dataset id, and row count, and stop — no workflow work. The moment the request grows beyond ingestion (enrich, run, connect a workflow), leave this lane and enter the gated path below.

## The Gated Build Path

**This path is gated.** If the request asks Freckle to produce, change, or run anything beyond the fast lane above, however small or clear it seems, your next action is to read [steps/step-1-context.md](steps/step-1-context.md) — the first command you run comes from that file. Several steps end in a question only the user can answer, so this path completes only in conversation with the user; finishing silently means the path was not followed.

Before anything else, write these six steps into your todo list, one item per step, using these exact labels — the user sees this list, so the labels stay jargon-free:

1. [Pick a workspace](steps/step-1-context.md) — derive the destination org from a named Workflow or Workbook, or the user picks it from the full org table.
2. [Nail down the goal](steps/step-2-objective.md) — check reuse across Workbooks and Workflows, then grill until no shape-changing unknowns remain.
3. [Scout the nodes and map the data](steps/step-3-contract-map.md) — inspect every planned node's contract and price; design the data mapping and outputs.
4. [Sign off on the plan](steps/step-4-plan.md) — render the workbook picture, diagram, result-fields table, and Credit Cost Summary; user approval freezes the plan.
5. [Set up the workbook and build it](steps/step-5-draft.md) — stand up the Workbook and load the data first, then author the frozen plan faithfully; validate until the compile response prints `ok: true`.
6. [Wire it up and run it](steps/step-6-run.md) — ship the Workflow, connect it to the Workbook, run through the sample gate.

Read each step file only when entering that step, and start the next step only after the current step's completion criterion passes. The user gates are steps 1, 2, and 4; steps 3 and 5 flow without pausing, and step 6 pauses only for a deviation or its sample gate — plan approval at step 4 covers the wiring and run intent. When a message to the user ends a step, describe what happens next accurately; never promise an action that belongs to a later step.

Every message to the user speaks to a GTM or marketing audience, not developers. Product language is fine — Workbook, Dataset, node, Workflow, org, run, provider, Research Agent — users know those words. Translate programming jargon: "the checks pass" not "validation exits 0", "what each column will show" not "typed object output", "connected" not "bound to the output port". Keep the tone plain and a little playful.

The work is **contract-first**: inspect node contracts before authoring, preview dynamic nodes after their config exists, validate drafts before save or publish, and map dataset fields only against the workflow's published input shape. The output of `workflow node inspect`, `workflow node preview`, `workflow draft validate`, and `workbook inspect` is authoritative — anything those commands can tell you, look up there. Node, saved-workflow, and run commands live in [workflow/cli-reference.md](workflow/cli-reference.md); workbook commands and semantics live in [WORKBOOKS.md](WORKBOOKS.md); the steps tell you when to use them.

## Non-Building Requests

| Request | Load |
| --- | --- |
| Scoped tweak to an existing Workflow or Workbook — swap a provider, change an output field, adjust config or a mapping | [REFINE.md](REFINE.md) — it owns the fit test and escalates redesigns back here |
| Run an existing saved Workflow directly with JSON inputs, inspect runs, list saved Workflows | [workflow/cli-reference.md](workflow/cli-reference.md) — apply its sample gate before any run over user rows |
| Workbook housekeeping that changes nothing about what runs — inspect, archive, delete entries, rotate webhook secrets | [WORKBOOKS.md](WORKBOOKS.md) |
| Inspect node capabilities | [workflow/cli-reference.md#node-catalog](workflow/cli-reference.md#node-catalog) |
| Debug a failing draft validation | [workflow/draft-syntax.md](workflow/draft-syntax.md) |
| Reason about an existing enrichment Workflow | [workflow/waterfall.md](workflow/waterfall.md), [workflow/collector.md](workflow/collector.md), [workflow/research-agent.md](workflow/research-agent.md) — recognize provider ordering, fallback branches, the collector, and the Research Agent's role before touching them |

Changing an existing Workflow or Workbook beyond a scoped tweak — a redesign of its shape — is building: it goes through the gated path above.
