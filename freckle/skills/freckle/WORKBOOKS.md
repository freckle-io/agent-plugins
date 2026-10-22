# Freckle Workbooks Reference

Commands and semantics for Workbooks, Datasets, and Workflow Dataset Connections. If the current request builds or changes what a Workbook runs and you have not entered the gated path in [BUILD.md](BUILD.md) or the refine path in [REFINE.md](REFINE.md), go back — these commands do not replace those paths.

A **Workbook** contains Datasets and connections. A **connection** reads entries from one input Dataset, maps them into a saved Workflow's inputs, runs them, and collects results into one output Dataset it creates in the same Workbook. The output Dataset holds only the newest result per input row — re-running a row replaces its outputs, never appends.

Follow [shared operating rules](SKILL.md#shared-operating-rules) for organization overrides and JSON input/output flags. Command help documents file inputs.

## Workbooks

```bash
freckle workbook create --label "Leads" --description "Lead enrichment"
freckle workbook list
freckle workbook list --archived
freckle workbook inspect <workbook-id>
freckle workbook update <workbook-id> --label "Qualified Leads"
freckle workbook archive <workbook-id>
freckle workbook unarchive <workbook-id>
```

`workbook list` rows include each Workbook's Datasets (`id`, `label`, `fieldPaths`, `archivedAt`) and connections (`workflowId`, input/output dataset ids, `triggerPolicy`, `archivedAt`) — enough to see what every Workbook does without inspecting each one. `workbook inspect` returns the full graph: Datasets with complete field catalogs, and connections with input mappings and unfold config. Archived Datasets and connections stay visible in both with `archivedAt` set; they refuse ingestion and triggers.

## Datasets

```bash
freckle workbook dataset list <workbook-id>
freckle workbook dataset create <workbook-id> --label "<label>" --description "<description>"
freckle workbook dataset inspect <workbook-id> <dataset-id>
freckle workbook dataset archive <workbook-id> <dataset-id>
freckle workbook dataset delete <workbook-id> <dataset-id>
```

Read `freckle workbook dataset entry list --help` for reading entries, pagination, and projections.

Entry changes:

```bash
freckle workbook dataset entry create <workbook-id> <dataset-id> --input-json '{"email":"person@example.com"}'
freckle workbook dataset entry create <workbook-id> <dataset-id> --file entry.json
freckle workbook dataset entry update <workbook-id> <dataset-id> <entry-id> --file entry.json
freckle workbook dataset entry delete <workbook-id> <dataset-id> <entry-id...>
```

Entry deletion is asynchronous and also deletes downstream entries derived through workflow lineage.

For CSV ingestion, choose the destination first and read the matching help for inputs, limits, key behavior, and failure handling:

- Existing Dataset: `freckle workbook dataset csv import --help`.
- New Dataset in an existing Workbook: `freckle workbook dataset build new csv --help`.

## Sources and keys

```bash
freckle workbook dataset source list <workbook-id> <dataset-id>
freckle workbook dataset webhook create <workbook-id> <dataset-id> --key-path /email
freckle workbook dataset webhook rotate <workbook-id> <source-id>
freckle workbook dataset hubspot create <workbook-id> --label "HubSpot List Contacts" --credential-id <credential-id> --object-type contacts --property email --property firstname --list-id <stable-list-id> --request-id <stable-request-id>
freckle workbook dataset hubspot inspect <workbook-id> <source-id>
freckle workbook dataset hubspot fetch-next-batch <workbook-id> <source-id> --request-id <stable-request-id>
```

Every entry enters through a source — `manual`, `csv_upload`, `webhook`, `hubspot`, `salesforce`, `signal`, `apollo_company_search`, `apollo_people_search`, `ai_ark_company_search`, `ai_ark_people_search`, `workflow_output`, or `workflow_node` — and carries a **source key** that identifies its logical record within the Dataset. A Dataset is the entry container and may have multiple configured sources; each entry belongs to exactly one. Repeat-key behavior depends on the source:

- CSV: choose a stable `--key-column` when repeated imports should update the same logical records.
- Webhook: key is the value at `--key-path` (JSON Pointer) in each posted record; must be a non-empty scalar.
- HubSpot: key identifies the portal, object type, and HubSpot object id; later HubSpot imports update the same logical records instead of duplicating them. Records no longer returned by HubSpot remain in the Dataset.
- Salesforce: key identifies the Salesforce org, object type, and record id; later Salesforce imports update the same logical records instead of duplicating them. Records no longer returned by Salesforce remain in the Dataset, except in a `--mirror` list-view source, which requests deletion for records that left the list view.
- Manual entries: keyed by their own id; `entry update` replaces the value and bumps the version.
- Workflow node entries: written by Push to Dataset through one reused `workflow_node` source per Dataset; their keys identify the producing Workflow Run, node, and array index. Repeating the same run/node/index reuses the entry; a separate run has distinct keys. See [workflow/push-to-dataset.md](workflow/push-to-dataset.md).

Webhook source output may include an `endpointUrl`. Return an already-obtained endpoint only to the authenticated requester. Treat it as a bearer credential: anyone holding the URL can ingest data into the Dataset. Use an endpoint returned by the requester's authenticated command output when they need the existing URL. Never create or rotate a source merely to recover an existing endpoint. Systems using the endpoint POST one JSON object or an array of them (limits: 1000 records and 5 MB per request, 100 requests/min). `webhook rotate` invalidates the old URL.

### Manual HubSpot imports

Read the selected command's `--help` before composing any `hubspot` command. Help owns syntax, examples, selection criteria, constraints, and output shapes.

| Goal | Command |
| --- | --- |
| Import HubSpot records into a new Dataset, once or on a schedule | `freckle workbook dataset hubspot create` |
| Check an import, its schedule, and where the next import starts | `freckle workbook dataset hubspot inspect` |
| Import what is new since the last import, now | `freckle workbook dataset hubspot fetch-next-batch` |
| Add, change, or delete a schedule | `freckle workbook dataset hubspot schedule set` or `schedule remove` |
| Stop scheduled imports for a while, then continue where they stopped | `freckle workbook dataset hubspot schedule pause` and `schedule resume` |
| Start the next list import from a chosen time | `freckle workbook dataset hubspot checkpoint` |

- `hubspot create` always creates a new Dataset. Get an authorized credential ID with `freckle connections show hubspot --org-id <org-id>`.
- Select records only as the user approved: one list, all records, or filter-group criteria. Never guess a list ID or filter.
- Give each create and fetch-next-batch its own stable `--request-id`, and reuse an ID only to retry that same operation.
- Before relying on an import's entries, wait for it as `hubspot fetch-next-batch --help` describes: a scheduled source returns a null `run`, and a large list arrives in several batches.

### Manual Salesforce imports

Read the selected command's `--help` before composing any `salesforce` command. Help owns syntax, examples, selection, constraints, and output shapes.

| Goal | Command |
| --- | --- |
| Find objects, fields, and list views to import | `freckle workbook dataset salesforce objects`, `fields`, or `list-views` |
| Check custom SOQL before importing it | `freckle workbook dataset salesforce soql preview` |
| Import Salesforce records into a new Dataset, once or on a schedule | `freckle workbook dataset salesforce create` |
| Check an import and its schedule | `freckle workbook dataset salesforce inspect` |
| Import what is new since the last import, now | `freckle workbook dataset salesforce fetch-next-batch` |
| Add, change, or delete a schedule | `freckle workbook dataset salesforce schedule set` or `schedule remove` |

- `salesforce create` always creates a new Dataset. Get an authorized credential ID with `freckle connections show salesforce --org-id <org-id>`.
- Select records only as the user approved: one list view, new records of one object, or custom SOQL. Never guess a list view or query.
- **Custom SOQL preview gate:** write the SOQL to an absolute file and run `salesforce soql preview` on that exact file until it exits 0 and the object, fields, and rows match the goal; only then run `salesforce create --soql-file` with the same file. Zero rows is a valid preview: tell the user it matched nothing and adjust the filters when that misses the goal.
- Give each create and fetch-next-batch its own stable `--request-id`, and reuse an ID only to retry that same operation.
- Before relying on an import's entries, wait for it as `salesforce fetch-next-batch --help` describes: a scheduled source returns a null `run`.

## Field catalogs

The **field catalog** names the Dataset fields Freckle can render as columns and map into workflow inputs — entries may hold extra fields, but only cataloged ones are mappable. Catalog format (`--file catalog.json`, either `{ "fieldCatalog": [...] }` or the bare array):

```json
[{ "id": "email", "path": "/email", "label": "Email", "type": "string", "visible": true, "order": 0 }]
```

Types: `string`, `number`, `boolean`, `json`. An empty catalog is seeded automatically from the first field-bearing manual entry, webhook batch, CSV import, or Push to Dataset write; a connection's output Dataset is seeded from the workflow's output shape. Empty objects remain valid for constant-only Workflow rows and leave the catalog empty until a later field-bearing write. Once a catalog is non-empty, ingestion never extends or changes it; edits are explicit:

```bash
freckle workbook dataset catalog replace <workbook-id> <dataset-id> --file catalog.json
```

## Connections

```bash
freckle workbook dataset connection create <workbook-id> <input-dataset-id> <workflow-id> --file mapping.json --output-label "Enriched" --trigger-policy manual
freckle workbook dataset connection inspect <workbook-id> <connection-id>
freckle workbook dataset connection trigger <workbook-id> <connection-id>
freckle workbook dataset connection trigger <workbook-id> <connection-id> --limit 10
freckle workbook dataset connection run <workbook-id> <connection-id> <entry-id>...
freckle workbook dataset connection rerun-failed <workbook-id> <connection-id>
freckle workbook dataset connection runs <workbook-id> <connection-id> --limit 25
freckle workbook dataset connection set-trigger-policy <workbook-id> <connection-id> --trigger-policy auto
freckle workbook dataset connection set-rerun-policy <workbook-id> <connection-id> --interval-days 7 --stop-output-id converted
freckle workbook dataset connection set-rerun-policy <workbook-id> <connection-id> --cron "0 9 * * 1"
freckle workbook dataset connection clear-rerun-policy <workbook-id> <connection-id>
freckle workbook dataset connection archive <workbook-id> <connection-id>
```

`connection create` requires an active (non-archived) Workflow with a published revision, creates the output Dataset in the same Workbook, and returns the connection with `outputDatasetId` — keep both ids. Add `--unfold-output-id <outputId>` to unfold (below). With `--trigger-policy auto`, the `set-rerun-policy` flags (`--interval-days` or `--cron`, and `--stop-output-id`) give it a Rerun Policy (below) from the start.

`connection archive` archives the connection and its output Dataset together, and returns the connection with `archivedAt` set. An archived connection refuses triggers, re-runs, and trigger and rerun policy changes; auto admission skips it; queued runs fail instead of starting; runs already executing still write their results. Its Dataset Entry Runs and output entries stay readable. Connections that read the archived output Dataset stop triggering too. Archiving again is a no-op, and there is no unarchive.

### Input mappings

The mapping file assigns every workflow input a cataloged field or a constant:

```json
{
  "email": { "kind": "field", "fieldId": "email" },
  "region": { "kind": "constant", "value": "EMEA" }
}
```

Keys are the workflow's input ids (see `shape` on `workflow saved list` or `schema` on `workflow saved inspect`); `fieldId` is a field catalog id on the input Dataset. Field types must be assignable to the input types. The mapping is checked at creation *and* re-checked against the workflow's current contract at every trigger — publishing a revision that breaks the mapping makes triggers reject with a diagnostic.

### Pending and triggering

An entry is **pending** for a connection when its current version has no recorded run for that connection — new entries, updated entries, and upserted entries all pend; admitting a run un-pends that version.

- A manual `trigger` admits pending entries oldest-first (by entry creation), at most 1,000 per call (`--limit 1..1000` to admit fewer, e.g. a sample of the first rows). Loop until `startedCount` is 0 to drain a large Dataset.
- `--trigger-policy auto` starts runs as entries become pending. Switching a connection to auto does **not** catch up already-pending entries — trigger manually first, then flip.
- Failed runs never retry automatically. `rerun-failed` re-runs failed current-version entries, reusing their ledger records (no retry history).
- A **Rerun Policy** reruns each entry on a schedule after its last successful run, to keep results fresh (re-enrich a lead weekly). Only auto connections take one; `set-trigger-policy manual` clears it, and switching back to auto does not restore it. Give exactly one schedule: `--interval-days 1..365` counts from when the run completed; `--cron` takes an expression with exactly one minute and one hour (at most daily), read in the Workspace's Customer Timezone (UTC when unset; `org list` shows it as `timeZone`, and `org set-time-zone <iana-zone> --org-id=<org-id>` changes it, `UTC` included, keeping reruns already scheduled at their times). `--stop-output-id` names a required boolean Workflow output: an entry reruns only while its run outputs `false`; anything else stops it. A changed policy applies after each entry's next run; already scheduled reruns keep their times, and after `clear-rerun-policy` they are dropped when they fall due. A rerun is skipped when the entry changed since (the new version runs as pending) or is already running; a failed run schedules nothing.
- `runs` pages the ledger: each record binds one input entry version to one Workflow run, with status (`running`/`completed`/`failed`/`discarded`) and failure detail.

### Explicit entry runs

`connection run` sends one ordered batch of 1–1,000 unique Dataset Entry ids. The entries must be current members of the connection's input Dataset; local argument errors make no request. The response preserves one result per requested id in the same order:

- `started` or `rerun` means Workflow Run Acceptance succeeded and includes the Dataset Entry Run and Workflow Run ids.
- `skipped` means an active run already exists; `rejected` means the entry was unavailable or belonged to another Dataset.
- `failed` means admission reached a stable failure such as stale input, Workflow Run rejection, an unavailable connection, or an internal error. Read each stable `reason` and `diagnostic`.

Missing entries and logically deleted entries both return `rejected/not_found`; entries found in another Dataset return `rejected/wrong_dataset`.

A mixed response is successful: inspect every result instead of treating a zero exit status as proof that every entry was accepted. These results report **Workflow Run Acceptance, not execution completion**; use `connection runs` or Workflow Run inspection to follow accepted runs to terminal state.

Connections are live bindings, not revision pins. Workflow Run Acceptance selects the latest Workflow Revision for each entry, so publishing a newer Workflow Revision changes later runs without recreating the connection.

### Outputs and unfold

Each successful run upserts output entries keyed to its input entry: re-running an input replaces its outputs in place (re-pending them for any downstream connection), results from a stale input version are discarded, and a failed run writes nothing. A downstream Workflow Dataset Connection with an auto trigger policy may admit those new or replaced outputs without another manual trigger. Output values are exactly the workflow output; lineage (`producedByRunId`, `producedFromEntryId`, `producedFromEntryVersion`) sits beside the value.

**Unfold** elects one array-of-objects workflow output at creation (`--unfold-output-id`): each array element becomes its own output entry, sibling workflow outputs are not collected, and re-runs remove surplus elements the newer result no longer produces.

## Limits and workarounds

- A connection's mapping, unfold config, and output label cannot be edited, and connections cannot be deleted or unarchived. To change a mapping: create a new connection on the same input Dataset (allowed — one Dataset can feed many connections), which creates a fresh output Dataset; then `connection archive` the old one. Archiving the old connection archives its output Dataset, so first check `workbook inspect` for connections whose input is that output: each one stops triggering and needs a replacement connection reading the new output Dataset.
- The CLI cannot rename or unarchive a Dataset; a Dataset can be hard-deleted only while no connection, archived or not, references it.
- No CSV export; read output entries with `dataset entry list`.
- An input Dataset may feed many connections, and a connection never crosses Workbooks.
- Archived Workbooks/Datasets refuse ingestion and triggers; archiving a Workbook starts asynchronous Signal cleanup, and unarchiving does not recreate its Signals.
