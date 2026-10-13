# Existing Workbooks and Workflows

The existing target's design is the brief. Stay here for scoped edits, adding rows/Datasets, or requested runs when intent can be completed with sensible reversible defaults. Escalate to BUILD only for genuine redesign or unresolved choices that change providers, outputs, destination, failure behavior or run shape.

1. Locate within `workspace_context`'s org using `workbooks_listWorkbooks` and `workflows_listWorkflows`, following cursors and archived Workbooks when needed. For a Dataset, find its containing Workbook. Zero/multiple matches require resolving the target; never create a replacement silently.
2. Inspect `workbooks_getWorkbook` or `workflows_getWorkflow`, then `workflows_getWorkflowRevision` for the saved draft. Inspect upstream producing Workflows and all Workbook connections reading the changed Workflow, including archived ones.
3. Pin the requested change. Ask only unresolved shape-changing decisions in one batch. The user's answers are approval; otherwise act directly without a new diagram or plan cycle.
4. Inspect each changed node using `workflowNodes_getWorkflowNode`; load waterfall, Apollo people, or Push references when relevant. Preview dynamic config, compile, then `workflows_saveWorkflowRevision`. Preserve existing data/wiring unless asked to change it.
5. Verify affected mappings against the new input shape and explicitly merge output catalogs when output columns change. Mappings/unfold/output labels are immutable: use a new connection and leave the old one manual.
6. Run only when asked. Specific entries use `datasets_runWorkflowDatasetConnectionEntries`; oldest pending use `datasets_triggerWorkflowDatasetConnection`. Follow accepted run IDs with `workflowRuns_getWorkflowRunData`. Apply WORKBOOKS' sample gate.

Report what changed, which readers/columns it affects, the returned link, and verified run outcomes.
