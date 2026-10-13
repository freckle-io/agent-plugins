# Wire and run

Create the new saved Workflow with `workflows_createWorkflow` or publish a revision with `workflows_saveWorkflowRevision`. Inspect the published schema, then create the approved Dataset connection using `datasets_createWorkflowDatasetConnection` and exact mappings/unfold. Start manual so loading data cannot bypass the sample gate. Reused connections need no duplicate wiring.

Run only the approved intent. More than 20 rows: run ten representative entry IDs with `datasets_runWorkflowDatasetConnectionEntries`, retain accepted run IDs, poll terminal results, inspect quality and sum actual credits. Show the [Credit Forecast Summary](../workflow/credit-cost.md), then get approval for the remainder. Do not rerun the sample. With 20 or fewer, admit the approved rows directly. Feed-and-run reuse still follows this gate.

Inspect each mixed admission outcome and all failures. Use `datasets_listWorkflowDatasetConnectionRuns` and `workflowRuns_getWorkflowRunData`; read the output Dataset with cursor pages and reconcile stored counts. Enable automatic triggering only when approved, after handling already-pending rows; switching to auto is not catch-up.

Deliver returned Workbook/Workflow links, what ran, actual completed/failed/pending counts, useful representative results, and cost evidence. Never report acceptance as success. Any plan-shape deviation returns to the affected decision first.
