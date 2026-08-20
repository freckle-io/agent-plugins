# Credits and Usage

Use this route when the user asks for a credit balance, spend, usage, or an enrichment breakdown. These commands report the Active Organization's exact recorded credits; planning maximums and sample forecasts live in [credit-cost.md](workflow/credit-cost.md).

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

Choose the narrowest report that answers the question:

| Question | Command | Breakdown |
| --- | --- | --- |
| How many credits remain? | `credit current` | Current Workspace balance |
| What did this Workspace use? | `credit usage` | Workbooks, plus usage outside a Workbook |
| What ran inside this Workbook? | `credit workflow-usage --workbook-id …` | Workflows in that Workbook |
| Which enrichments consumed credits in this Workbook? | `credit workbook-node-usage --workbook-id …` | Billed nodes across the Workbook |
| Which enrichments consumed credits for this Workflow? | `credit workflow-node-usage --workflow-id …` | Billed nodes across every context in which the Workflow ran |

Resolve a named Workbook or Workflow and pin its org by the shared rules in [SKILL.md](SKILL.md#shared-operating-rules) before running a scoped report. A Workflow report within a Workbook requires the Workbook id; a Workflow node report follows that Workflow across standalone and Workbook runs.

## Dates and output

`--from` and `--to` are inclusive UTC calendar dates in `YYYY-MM-DD` form. With neither flag, the range is the current UTC day. Supplying only one makes it the value of both, producing a one-day report.

Usage responses return `creditsConsumed` and `enrichments` as exact decimal strings. Preserve those strings when presenting or calculating totals; use decimal arithmetic rather than binary floating-point conversion. `enrichments` counts billed node operations, not top-level Workflow Runs. One Workflow Run can therefore contribute several enrichments.

Node reports group charges by the billed `category` and `topic`. Workbook and Workflow summaries include their ids and nullable labels. In Workspace usage, `workbookId: null` is usage outside a Workbook; a non-null id with a null label can identify a deleted Workbook. Workbook Workflow summaries may include synthetic Signal identifiers as well as saved Workflow UUIDs.

Usage reports read aggregates rolled up every five minutes. The rollup leaves events less than 30 seconds old for its next pass, so a report can trail completed runs by more than one cycle. Treat a usage snapshot as settled only after waiting six minutes and seeing the same result again; if it changed, use the newer result and repeat the settle check.

## Sample credit evidence

The usage API is aggregate evidence, not per-run or per-entry attribution. To measure a sample, settle the narrowest report for the same UTC date before admission. After every sample run is terminal, settle that report again, then subtract the baseline `creditsConsumed` from the final value. In a `workflow-usage` response, compare the matching item in `workflows`, not the all-Workflow top-level total. Use:

- `workbook-node-usage` for a sample whose full cost stays in one Workbook;
- `workflow-usage` when isolating one Workflow inside a Workbook; or
- `workflow-node-usage` for direct saved-Workflow runs.

Call the delta **actual sample credits** only when no unrelated work used that same report scope between snapshots. Otherwise state that aggregate activity prevents trustworthy sample attribution and keep the planning maximum as context. Apply [credit-cost.md](workflow/credit-cost.md) for the user-facing **Credit Forecast Summary**.

**Completion** — every box checked:

- [ ] The requested current balance or narrowest usage report was run for the resolved org; every usage result was presented with its inclusive `from` and `to` dates.
- [ ] Exact strings and enrichment semantics were preserved.
- [ ] Every usage snapshot used as evidence passed the six-minute settle check.
- [ ] Aggregate totals were attributed to a sample only when settled before/after snapshots and scope isolation made that attribution trustworthy.
