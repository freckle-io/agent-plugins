# Credit Cost and Forecast Summaries

This is the single source of truth for user-facing credit planning and forecast messaging. Apply it when planning or running a Workflow; [CREDITS.md](../CREDITS.md) owns balance and usage reporting.

## Calculate the maximum

Use current catalog data internally. `creditCostModel` tells you whether a node's `creditCost` is charged at most once for a billable execution, once per billable result, or whether its exact charge is calculated from metered provider usage after execution; these are implementation details, not user-facing terms.

For one input row:

1. Add each at-most-once node's `creditCost` once, including every provider that could run across fallback branches.
2. For each per-result node with a configured result cap, add `creditCost × cap`. Without a cap, keep `creditCost × billable results` as a formula and say a finite maximum is unavailable until the cap is known.
3. Treat each usage-priced node as an unknown pre-run charge. Managed Apify converts the provider-reported Apify USD cost after execution into Freckle credits using `Apify usage USD ÷ (Workspace plan price USD ÷ plan credits)` — Workspaces without a current paid plan use the default plan rate ($99 for 1,000 credits) — so a finite maximum is unavailable before the Actor run reports its usage. BYOK Apify uses 0 Freckle credits, while Apify may charge the selected Integration Connection.
4. When the Dataset size is fixed, multiply the complete per-row maximum by the row count. If any component remains uncapped or usage-priced, show its full-workbook formula instead of a finite total.

For a saved Workflow reused unchanged:

1. Run `workflow saved inspect`, capture the quoted revision id and `costEstimate`, and use `estimatedStaticCreditCost` as the at-most-once subtotal.
2. When `dynamicNodeCosts` is non-empty, export that exact revision before resolving caps:

   ```bash
   freckle workflow saved get-draft <workflowId> --revision-id <revisionId> --out <absolute-path>/workflow.yaml
   ```

3. Trace each result-priced node's cap through the exported draft's config, constants, and fixed request construction. Apply its unit price only when the cap is fixed and verified. When the cap is input-dependent or cannot be verified, keep `creditCost × billable results` as an uncapped formula and state that a finite maximum is unavailable.
4. When `usageBasedNodeCosts` is non-empty, list those nodes as post-run charges and state that a finite maximum is unavailable before their metered provider usage is known. For managed Apify, use the plan-conversion formula above; do not treat the catalog's placeholder `creditCost` as a quote.

Identify the quoted revision in the summary. The latest revision is mutable and inspect-before-admission is not atomic, so say the maximum or formula can change if a new revision or catalog price lands before the run.

## Plan: Credit Cost Summary

In the approved plan, omit credits from the result-fields table. Follow it with this exact heading:

**Credit Cost Summary**

Report:

- maximum credits per row;
- maximum credits for the whole Workbook only when the Dataset size and every result cap are fixed and no usage-priced charge remains;
- any uncapped per-result formula that prevents a finite maximum;
- any usage-priced node and its post-run calculation that prevents a finite maximum;
- that averages and forecasts become eligible after the first 10 input rows’ runs reach terminal states and require trustworthy actual sample credits; and
- which before/after usage scope from [CREDITS.md](../CREDITS.md#sample-credit-evidence) will measure the sample, or that concurrent aggregate activity prevents trustworthy attribution.

Label every user-facing credit amount **credits**. Describe per-result and provider-usage formulas in plain language when needed, without exposing the catalog's billing-model labels. State that a finite maximum is an upper bound at current prices, not a range or a guaranteed charge; a row may use 0 credits. Authenticated dollar equivalents follow the rules below.

## After the sample: Credit Forecast Summary

After the first 10 input rows’ runs reach terminal states, return this heading even when a trustworthy forecast is unavailable:

**Credit Forecast Summary**

An observed forecast requires actual sample credits from isolated before/after usage snapshots for those 10 rows. Settle the baseline before admission and follow [CREDITS.md](../CREDITS.md#sample-credit-evidence); after every sample run reaches a terminal state, settle the final snapshot and subtract the baseline from its exact `creditsConsumed` total. When the report scope stayed isolated, report:

- sample size and actual sample credits;
- average credits per row (`sample credits ÷ 10`); and
- for a fixed Dataset, forecast total credits (`average credits per row × row count`).

Label this as a sample-based forecast, not a guarantee. Use the isolated aggregate delta as the sole observed-spend source; outputs, selected branches, catalog maximums, and a zero lower bound remain planning context.

When no baseline was captured, the rollup has not landed, or unrelated work shares the report scope, the **Credit Forecast Summary** states that trustworthy sample attribution is unavailable, then repeats the planning maximum for context and labels it as a maximum rather than an observed forecast.

## Dollar equivalents

Add dollars only when an authenticated product response supplies the user's plan-specific credit-to-dollar rate. Then show dollars per row beside credits, and show a total-workbook dollar figure only for a fixed Dataset size. Name the plan/rate source and calculation.

The current CLI does not expose the user's plan-specific rate. State that dollar equivalents are unavailable from the current CLI; never infer a rate from plan names, public pricing, or generic assumptions.

**Completion:** the plan has one **Credit Cost Summary** based on a verified maximum, an explicit uncapped formula, or an explicit post-run provider-usage calculation; after the first 10 input rows’ runs reach terminal states, one **Credit Forecast Summary** reports an isolated actual sample-credit delta or the explicit attribution limitation; credit-cost quantities use the label “credits,” while authenticated plan-rate dollar equivalents remain allowed; no per-data-point credit allocation or unsupported range appears; and total dollars appear only for a fixed Dataset size.
