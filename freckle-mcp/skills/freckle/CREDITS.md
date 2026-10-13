# Credits and Usage

Use this route when the user asks for a credit balance, spend, usage, or an enrichment breakdown. Use credit tools for general balance, historical or scoped usage, and enrichment breakdowns. Use Workflow Run inspection for a recent bounded set of known Run IDs; [sample credit evidence](#sample-credit-evidence) owns that split. Planning maximums and sample forecasts live in [credit-cost.md](workflow/credit-cost.md).

## Tools

Use `creditUsage_getCurrentCredits` for balance; `creditUsage_getUsageByDay` for daily totals; `creditUsage_getUsageByWorkbook` for Workspace usage; `creditUsage_getUsageByWorkflow` with workbookId for one Workbook; `creditUsage_getUsageByNodeInWorkbook` or `creditUsage_getUsageByNodeInWorkflow` for billed-node breakdowns. Supply inclusive from/to dates in query and report the returned date range. Resolve the consent-selected Workspace before scoped reports. Read the tool's JSON Schema for exact fields.

## Dates and output

Use the tool schema for date syntax; include the returned date range when reporting usage.

Usage tools return `creditsConsumed` and `enrichments` as exact decimal strings. Preserve those strings when presenting or calculating totals; use decimal arithmetic rather than binary floating-point conversion. `enrichments` counts billed node operations, not top-level Workflow Runs. One Workflow Run can therefore contribute several enrichments.

Node reports group charges by the billed `category` and `topic`. Workbook and Workflow summaries include their ids and nullable labels. In Workspace usage, `workbookId: null` is usage outside a Workbook; a non-null id with a null label can identify a deleted Workbook. Workbook Workflow summaries may include synthetic Signal identifiers as well as saved Workflow UUIDs.

## Plan rate and dollar equivalents

Credit responses carry `creditPricing`, the Workspace's authenticated credit-to-dollar rate: `planPriceUsdCents` (the plan's price in USD cents), `planCredits` (the credits that price buys), and `source` — `current-plan` for the Workspace's active paid plan, or `default` for the default rate ($99 for 1,000 credits) when the Workspace has no current paid plan. Tool outputs carry the raw exact values; calculate and format dollar equivalents from them.

Convert with `credits × planPriceUsdCents ÷ planCredits ÷ 100`. Quote dollars only from the response's `creditPricing`, and name its source whenever dollars are shown; never infer a rate from plan names, public pricing, or generic assumptions. Display a positive amount below half a cent as `<$0.01`.

`creditPricing` is optional on the wire: an older API deployment may omit it. When a response has no `creditPricing`, report credits only and say once that dollar equivalents are unavailable because the API did not report a plan rate. Do not substitute the default rate, and do not reuse a rate from another response.

## Sample credit evidence

A recent bounded sample uses exact Workflow Run evidence. Keep the exact admitted Run IDs; watch them with `workflowRuns_getWorkflowRunData` until every selected run reaches a terminal state, then inspect each one with `workflowRuns_getWorkflowRunData`. For a Workbook connection, keep the `workflowRunId` values printed by `datasets_runWorkflowDatasetConnectionEntries`; for direct saved-Workflow invocations, keep each returned `runId`.

Sum the exact decimal-string `creditsConsumed` across every selected run, including failed terminal runs, and call that total **actual sample credits**. Complete per-run evidence is isolated by construction, so unrelated activity cannot distort it. Report that total immediately even when aggregate usage has not recorded the runs yet.

The aggregate credit tools remain the source for general usage information, historical or wider scopes, and node/category breakdowns. They are a sample fallback only when an exact sample Run ID or its `creditsConsumed` is unavailable. For that fallback, capture the narrowest report for the same UTC date before admission. After every sample run is terminal, capture that report again, then subtract the baseline `creditsConsumed` from the final value. In a `creditUsage_getUsageByWorkflow` response, compare the matching item in `workflows`, not the all-Workflow top-level total. Use:

- `creditUsage_getUsageByNodeInWorkbook` for a sample whose full cost stays in one Workbook;
- `creditUsage_getUsageByWorkflow` when isolating one Workflow inside a Workbook; or
- `creditUsage_getUsageByNodeInWorkflow` for direct saved-Workflow runs.

Call the aggregate delta **actual sample credits** only when no unrelated work used that same report scope between snapshots. If the final snapshot has not recorded the sample or aggregate activity prevents trustworthy attribution, state that actual sample credits are unavailable at that moment and keep the planning maximum as context. Apply [credit-cost.md](workflow/credit-cost.md) for the user-facing **Credit Forecast Summary**.

**Completion** — every box checked:

- [ ] A general balance or usage request ran the narrowest credit tool for the resolved org; every usage result was presented with its inclusive `from` and `to` dates.
- [ ] Exact strings and enrichment semantics were preserved.
- [ ] A recent bounded sample with complete Run evidence used the sum of its terminal Runs' `creditsConsumed` immediately.
- [ ] Aggregate totals were attributed to a sample only when before/after snapshots and scope isolation made that attribution trustworthy.
- [ ] Every dollar amount shown came from the response's `creditPricing` rate with its source named; where the response omitted `creditPricing`, credits were reported alone with the unavailability stated once.
