# Workflow tools

## Node catalog

`workflowNodes_listWorkflowNodes` returns authorable definitions; `workflowNodes_getWorkflowNode` with params.definitionKey returns the full config/input/output/case/version/credit contract. Inspect each planned node. `workflowNodes_previewWorkflowNode` takes payload.draft plus targetNodeId to derive a dynamic contract after config exists. Preview does not execute provider work.

Author a JSON object using [draft-syntax.md](draft-syntax.md). Its YAML examples illustrate the same data model; pass parsed objects directly to tools. Validate with `workflowDrafts_compileWorkflowDraft` and read all diagnostics until `ok: true`. That only proves compilation, not provider success.

## Saved workflows

List with `workflows_listWorkflows` and query filters/cursor inside the current org. `workflows_getWorkflow` provides metadata, published schema and cost information. `workflows_listWorkflowRevisions` / `_getWorkflowRevision` retrieve revision history and editable draft. Use the returned draft object as the basis of edits; no file export step is required.

`workflows_createWorkflow` saves a new draft and metadata. `workflows_saveWorkflowRevision` publishes a new revision for an existing workflow. `workflows_updateWorkflow` edits metadata/lifecycle fields permitted by the schema; `_archiveWorkflow` / `_unarchiveWorkflow` manage availability. Keep the persisted UUID separate from the draft's workflowId slug. Reinspect after mutation and use returned URLs.

## Run saved workflows

Use `workflowRuns_startWorkflowRun` with the persisted workflow UUID and input object matching the inspected published schema. Keep externalInvocationId/runId when returned. Never repeat an ambiguous start without inspection; a correlation ID is not a guarantee of deduplication.

`workflowRuns_getWorkflowRunData` inspects a known run; `_listWorkflowRuns` pages filtered history. Poll accepted IDs until terminal and inspect outputs/errors/credits. `_cancelWorkflowRuns` cancels selected IDs; `_cancelAllWorkflowRuns` is broader and needs corresponding user intent. For Dataset-bound work prefer the connection tools so lineage and output collection are preserved.

More than 20 user rows requires WORKBOOKS' ten-row sample gate. Admission/rejection is distinct from completion. For failed runs, read node diagnostics: invalid config calls for draft correction and republish; provider authentication needs reconnection; credits need balance/plan evidence; missing input calls for mapping/data repair. Do not replace an approved provider or fallback without revisiting the plan.
