# Set up and build

Implement the approved shape faithfully. Create the Workbook/input Dataset and ingest the approved data using WORKBOOKS or CRM. Prepare any same-Workbook Push destinations with complete merged catalogs before drafting.

For reuse, retain the inspected published shape. For a new/editable draft, use [draft-syntax.md](../workflow/draft-syntax.md), exact pinned node versions, inspected ports/cases, and approved providers/fallback order. Choose one convergent collector per result rather than duplicating downstream chains. Keep typed result columns and failure outcomes from the plan.

Pass the draft JSON to `workflowNodes_previewWorkflowNode` for dynamic nodes after config is present, then `workflowDrafts_compileWorkflowDraft`. Fix all diagnostics until `ok: true`. Plumbing fixes do not change the approved goal; substitutions or omitted fallback branches do, and require revisiting the plan.

Completion: Workbook/data/destinations match the plan, dynamic contracts are verified, the exact final draft compiles, and no plan deviation is hidden. Continue to [step-6-run.md](step-6-run.md).
