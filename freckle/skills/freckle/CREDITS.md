# Credits and Usage

Use this route when the user asks for a credit balance, spend, usage, or an enrichment breakdown. Use the `credit` commands for general balance, historical or scoped usage, and enrichment breakdowns. Use Workflow Run inspection for a recent bounded set of known Run IDs; [sample credit evidence](#sample-credit-evidence) owns that split. Planning maximums and sample forecasts live in [credit-cost.md](workflow/credit-cost.md).

## Commands

```bash
freckle credit current
freckle credit current --json

freckle credit usage
freckle credit usage --from 2026-08-01 --to 2026-08-06 --json

freckle credit workflow-usage --workbook-id <workbook-id>
freckle credit workflow-usage --workbook-id <workbook-id> --from 2026-08-01 --to 2026-08-06 --json

freckle credit workbook-node-usage --workbook-id <workbook-id>
freckle credit workbook-node-usage --workbook-id <workbook-id> --from 2026-08-01 --to 2026-08-06 --json

freckle credit workflow-node-usage --workflow-id <workflow-id>
freckle credit workflow-node-usage --workflow-id <workflow-id> --from 2026-08-01 --to 2026-08-06 --json
```

Choose the narrowest general report that answers the question:

| Question | Command | Breakdown |
| --- | --- | --- |
| How many credits remain? | `credit current` | Current Workspace balance |
| What did this Workspace use? | `credit usage` | Workbooks, plus usage outside a Workbook |
| What ran inside this Workbook? | `credit workflow-usage --workbook-id …` | Workflows in that Workbook |
| Which enrichments consumed credits in this Workbook? | `credit workbook-node-usage --workbook-id …` | Billed nodes across the Workbook |
| Which enrichments consumed credits for this Workflow? | `credit workflow-node-usage --workflow-id …` | Billed nodes across every context in which the Workflow ran |

Resolve the org for a named Workbook or Workflow by the shared rules in [SKILL.md](SKILL.md#shared-operating-rules) before running a scoped report. A Workflow report within a Workbook requires the Workbook id; a Workflow node report follows that Workflow across standalone and Workbook runs.

## Dates and output

`--from` and `--to` are inclusive UTC calendar dates in `YYYY-MM-DD` form. With neither flag, the range is the current UTC day. Supplying only one makes it the value of both, producing a one-day report.

Usage commands print `creditsConsumed` and `enrichments` as exact decimal strings. Preserve those strings when presenting or calculating totals; use decimal arithmetic rather than binary floating-point conversion. `enrichments` counts billed node operations, not top-level Workflow Runs. One Workflow Run can therefore contribute several enrichments.

Node reports group charges by the billed `category` and `topic`. Workbook and Workflow summaries include their ids and nullable labels. In Workspace usage, `workbookId: null` is usage outside a Workbook; a non-null id with a null label can identify a deleted Workbook. Workbook Workflow summaries may include synthetic Signal identifiers as well as saved Workflow UUIDs.

## Plan rate and dollar equivalents

Credit responses carry `creditPricing`, the Workspace's authenticated credit-to-dollar rate: `planPriceUsdCents` (the plan's price in USD cents), `planCredits` (the credits that price buys), and `source` — `current-plan` for the Workspace's active paid plan, or `default` for the default rate ($99 for 1,000 credits) when the Workspace has no current paid plan. Human-readable output already prints each credit amount with its dollar equivalent beside it and the rate on one line; `--json` carries the raw fields.

Convert with `credits × planPriceUsdCents ÷ planCredits ÷ 100`. Quote dollars only from the response's `creditPricing`, and name its source whenever dollars are shown; never infer a rate from plan names, public pricing, or generic assumptions. Display a positive amount below half a cent as `<$0.01`.

`creditPricing` is optional on the wire: an API deployment older than the CLI omits it, and human output then prints credits alone. When a response has no `creditPricing`, report credits only and say once that dollar equivalents are unavailable because the API did not report a plan rate. Do not substitute the default rate, and do not reuse a rate from another response.

## Sample credit evidence

A recent bounded sample uses exact Workflow Run evidence. Keep the exact admitted Run IDs; watch them with `freckle workflow saved runs watch <workflow-id> <run-id>...` until every selected run reaches a terminal state, then inspect each one with `freckle workflow saved runs inspect <workflow-id> <run-id>`. For a Workbook connection, keep the `workflowRunId` values printed by `workbook dataset connection run`; for direct saved-Workflow invocations, keep each returned `runId`.

Sum the exact decimal-string `creditsConsumed` across every selected run, including failed terminal runs, and call that total **actual sample credits**. Complete per-run evidence is isolated by construction, so unrelated activity cannot distort it. Report that total immediately even when aggregate usage has not recorded the runs yet.

The aggregate `credit` reports remain the source for general usage information, historical or wider scopes, and node/category breakdowns. They are a sample fallback only when an exact sample Run ID or its `creditsConsumed` is unavailable. For that fallback, capture the narrowest report for the same UTC date before admission. After every sample run is terminal, capture that report again, then subtract the baseline `creditsConsumed` from the final value. In a `workflow-usage` response, compare the matching item in `workflows`, not the all-Workflow top-level total. Use:

- `workbook-node-usage` for a sample whose full cost stays in one Workbook;
- `workflow-usage` when isolating one Workflow inside a Workbook; or
- `workflow-node-usage` for direct saved-Workflow runs.

Call the aggregate delta **actual sample credits** only when no unrelated work used that same report scope between snapshots. If the final snapshot has not recorded the sample or aggregate activity prevents trustworthy attribution, state that actual sample credits are unavailable at that moment and keep the planning maximum as context. Apply [credit-cost.md](workflow/credit-cost.md) for the user-facing **Credit Forecast Summary**.

**Completion** — every box checked:

- [ ] A general balance or usage request ran the narrowest `credit` report for the resolved org; every usage result was presented with its inclusive `from` and `to` dates.
- [ ] Exact strings and enrichment semantics were preserved.
- [ ] A recent bounded sample with complete Run evidence used the sum of its terminal Runs' `creditsConsumed` immediately.
- [ ] Aggregate totals were attributed to a sample only when before/after snapshots and scope isolation made that attribution trustworthy.
- [ ] Every dollar amount shown came from the response's `creditPricing` rate with its source named; where the response omitted `creditPricing`, credits were reported alone with the unavailability stated once.
