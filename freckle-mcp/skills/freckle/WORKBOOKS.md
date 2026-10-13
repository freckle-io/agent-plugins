# Workbooks, Datasets and connections

Use BUILD/REFINE for judgment about new or existing processing designs. These tools provide the mechanics.

`workbooks_listWorkbooks` (paged, including optional archived filter) returns Dataset/connection summaries. `workbooks_getWorkbook` returns the full graph with catalogs/mappings/unfold. Create/update/archive/unarchive use the corresponding `workbooks_` tools. Archived Workbooks/Datasets refuse ingestion and triggers; Workbook archive asynchronously cleans up Signals, and unarchive does not recreate them.

## Datasets and rows

Use `datasets_listWorkbookDatasets`, `datasets_createWorkbookDataset`, `datasets_getDataset`, `datasets_archiveDataset`, and `datasets_deleteDataset`. Dataset rename/unarchive is unavailable. Delete only an eligible Dataset with no referencing connection.

Read `datasets_listDatasetEntries` with `query.workbookId`, a bounded limit and returned cursor; use compact projections where supported. `datasets_createDatasetEntry` adds a manual value, `datasets_updateDatasetEntry` replaces it and bumps version, and `datasets_deleteDatasetEntries` asynchronously deletes rows and downstream lineage. Inspect every returned status, not just overall success.

For CSV, parse locally with the host's file tools, then call `datasets_importDatasetCsv` with `params.datasetId`, `query.workbookId`, and `payload` containing filename, ordered headers, optional stable keyColumn, and parsed rows. Small batches keep requests within the 5 MiB body and API row limit. No server file paths or shell commands. For a new Dataset, create it first. Repeated keys upsert; do not retry an ambiguous import without inspecting state. Export is client-side: page entries and render/save with the host's file tools.

## Sources and keys

Inspect `datasets_listDatasetSources`. Sources include manual, csv_upload, webhook, CRM, signals, list providers, workflow_output and workflow_node. Each entry belongs to one source; the Dataset can contain several sources.

- CSV stable keyColumn updates logical records across imports.
- Webhook keyPath is a JSON Pointer to a nonempty scalar. `datasets_createDatasetWebhookSource` creates a source; `datasets_rotateDatasetWebhookSourceSecret` invalidates its old URL. Return an existing endpoint from authenticated output; never create/rotate simply to recover it. Its URL is an ingestion bearer credential. Receivers accept one object or array, at most 1,000 records/5 MB per request and 100 requests/minute.
- CRM keys identify provider tenant, object type and record ID. Reimports update returned records; absent records remain. See [CRM.md](CRM.md).
- Push to Dataset reuses a workflow_node source with run/node/index keys; a separate run creates distinct keys. See [workflow/push-to-dataset.md](workflow/push-to-dataset.md).

## Field catalogs

Catalogs define visible and mappable columns; stored extra fields are not automatically mappable. Example field: `{"id":"email","path":"/email","label":"Email","type":"string","visible":true,"order":0}`. Types are string, number, boolean, json. Empty catalogs seed from the first field-bearing ingestion; later ingestion never extends a nonempty catalog. Use `datasets_replaceDatasetFieldCatalog` with a complete merged catalog, preserving existing fields. Empty input objects support constant-only runs.

## Input mappings

`datasets_createWorkflowDatasetConnection` reads an input Dataset, maps inputs to a saved Workflow, and creates a separate output Dataset in the same Workbook. Map each workflow input ID to a catalog field ID or constant using the exact schema. Inspect the published input shape first. Type assignability is checked at creation and every trigger. Connections follow the latest published revision, not a fixed revision.

Mappings, unfold and output label are immutable; connections cannot be deleted. A mapping change needs a new connection, with the old one left manual. One Dataset can feed multiple connections, but none cross Workbooks.

## Pending and triggering

An entry version is pending until it has an admitted run for that connection. `datasets_triggerWorkflowDatasetConnection` admits oldest pending rows, up to 1,000 per call. Use `payload.limit` for a sample; drain only the approved remainder, stopping at `startedCount: 0`.

`datasets_runWorkflowDatasetConnectionEntries` accepts ordered unique entryIds. started/rerun includes Workflow Run IDs; skipped means an active run; rejected identifies missing/wrong-Dataset entries; failed has a stable reason/diagnostic. Mixed responses are valid. Admission is not completion: retain every accepted ID and poll `workflowRuns_getWorkflowRunData` or the paged `datasets_listWorkflowDatasetConnectionRuns` ledger.

Failed runs never retry automatically. `datasets_rerunFailedWorkflowDatasetConnection` reuses failed current-version ledger records. `datasets_updateWorkflowDatasetConnectionTriggerPolicy` changes manual/auto: auto starts newly pending rows but does not catch up already-pending ones. Drain approved pending work first, then enable auto if requested.

## Sample gate

For more than 20 rows, admit ten representative entries first. Wait for each selected run to finish, inspect every result and failure, sum their exact decimal `creditsConsumed`, and show result quality plus the Credit Forecast Summary. Get approval for the remainder after this evidence. For 20 or fewer, run the approved rows directly. At ten or more completed input rows, return the Credit Forecast Summary; for fewer than ten, say the sample is too small for a forecast. A preset sample requested by the user stays that sample. Do not rerun an admitted sample as part of the remainder.

## Outputs and unfold

Successful runs upsert the newest result per input row; stale-version results are discarded and failures write nothing. Replaced outputs become pending for downstream connections. Lineage sits beside the value. Unfold selects one array-of-objects output into one row per element; sibling outputs are not collected, and reruns remove surplus old elements.
