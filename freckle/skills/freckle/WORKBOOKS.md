# Freckle Workbooks Reference

Commands and semantics for Workbooks, Datasets, and Workflow Dataset Connections. If the current request builds or changes what a Workbook runs and you have not entered [BUILD.md](BUILD.md) or [REFINE.md](REFINE.md), go back — these commands do not replace those paths.

A **Workbook** contains Datasets and connections. A **connection** reads entries from one input Dataset, maps them into a saved Workflow's inputs, runs them, and collects results into one output Dataset it creates in the same Workbook (newest result per input row; re-running a row replaces its outputs). Inline JSON input is `--input-json` or `--file`; append `--org-id=<org-id>` after the complete subcommand path.

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

`workbook list` rows include each Workbook's Datasets (`id`, `label`, `fieldPaths`, `archivedAt`) and connections (`workflowId`, input/output dataset ids, `triggerPolicy`). `workbook inspect` returns the full graph with field catalogs and mappings. Archived Datasets stay visible with `archivedAt` set and refuse ingestion and triggers.

## Datasets

```bash
freckle workbook dataset list <workbook-id>
freckle workbook dataset create <workbook-id> --label "<label>" --description "<description>"
freckle workbook dataset inspect <workbook-id> <dataset-id>
freckle workbook dataset archive <workbook-id> <dataset-id>
freckle workbook dataset delete <workbook-id> <dataset-id>
```

Entries and ingestion:

```bash
freckle workbook dataset entry list <workbook-id> <dataset-id> --limit 100
freckle workbook dataset entry create <workbook-id> <dataset-id> --input-json '{"email":"person@example.com"}'
freckle workbook dataset entry create <workbook-id> <dataset-id> --file entry.json
freckle workbook dataset entry update <workbook-id> <dataset-id> <entry-id> --file entry.json
freckle workbook dataset entry delete <workbook-id> <dataset-id> <entry-id...>
freckle workbook dataset csv import <workbook-id> <dataset-id> --file rows.csv --key-column email
freckle workbook dataset build new csv <workbook-id> rows.csv --label "Imported Leads" --key-column email
```

`build new csv` creates the Dataset and imports in one shot (deleting it again if the import fails). CSV imports: at most 10 MiB and 100,000 rows, first row is the header. Entry deletion is asynchronous and cascades to derived downstream entries.

### Reading every row

`entry list` returns at most 1,000 rows per call and a `nextCursor` when more remain. Do not write a shell loop for this. Use this exact recipe, redirecting to a file rather than piping (the CLI can truncate piped `--json` output at 64 KiB):

```bash
cat > /tmp/drain.py <<'PY'
import json, subprocess, sys
wb, ds, org = sys.argv[1], sys.argv[2], sys.argv[3]
rows, cursor = [], None
while True:
    cmd = ["freckle","workbook","dataset","entry","list", wb, ds, "--org-id="+org, "--json", "--limit", "1000"]
    if cursor: cmd += ["--cursor", cursor]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    page = json.loads(out)
    rows += page["entries"]
    cursor = page.get("nextCursor")
    if not cursor or not page["entries"]: break
json.dump(rows, open("/tmp/rows.json","w"))
print(len(rows))
PY
python3 /tmp/drain.py <workbook-id> <dataset-id> <org-id>
```

Then answer every question from `/tmp/rows.json`; never re-fetch to answer a second question.

`--ai-ark-companies` / `--ai-ark-people` are mutually exclusive compact projections for large stored payloads.

## Sources and keys

```bash
freckle workbook dataset source list <workbook-id> <dataset-id>
freckle workbook dataset webhook create <workbook-id> <dataset-id> --key-path /email
freckle workbook dataset webhook rotate <workbook-id> <source-id>
freckle workbook dataset hubspot create <workbook-id> --label "HubSpot List Contacts" --credential-id <credential-id> --object-type contacts --property email --property firstname --list-id <stable-list-id> --request-id <stable-request-id>
freckle workbook dataset hubspot inspect <workbook-id> <source-id>
freckle workbook dataset hubspot run-again <workbook-id> <source-id> --request-id <stable-request-id>
```

Every entry enters through a source (`manual`, `csv_upload`, `webhook`, `hubspot`, `salesforce`, `signal`, provider searches, `workflow_output`, `workflow_node`) and carries a **source key** naming its logical record. CSV with `--key-column`: re-imports update matching rows (without it, keys are positional and re-imports duplicate). Webhook: key at `--key-path`. HubSpot/Salesforce: key is the remote record id, so later imports update rather than duplicate. Workflow-node entries: see [workflow/push-to-dataset.md](workflow/push-to-dataset.md).

A webhook `endpointUrl` is a bearer credential: return it only to the authenticated requester, never create or rotate a source just to recover it. `webhook rotate` invalidates the old URL.

### HubSpot and Salesforce imports

`hubspot create` / `salesforce create` create a new Dataset with its source and (unless scheduled) start the first import; they do not attach to an existing Dataset. Get the credential id from `connections show <provider>`, repeat `--property` in retention order, and pass **exactly one** selection mode (HubSpot: `--list-id`, `--all-records`, `--criteria-json`/`--criteria-file`; Salesforce: `--list-id`, `--new-objects [--backfill]`, `--soql-file`). Give every create and run-again a stable `--request-id`; pass `--schedule` and `--time-zone` together or not at all. Read `latestRun.status` from `inspect` and poll to a terminal state. Custom SOQL must pass `salesforce soql preview` on the exact file before `create --soql-file`. Confirm exact flags with `--help`.

```bash
freckle workbook dataset salesforce objects --credential-id <credential-id>
freckle workbook dataset salesforce fields --credential-id <credential-id> --object-type Contact
freckle workbook dataset salesforce list-views --credential-id <credential-id> --object-type Contact
freckle workbook dataset salesforce create <workbook-id> --label "SF Contacts" --credential-id <credential-id> --object-type Contact --property Email --property FirstName --list-id <list-view-id> --request-id <stable-request-id>
freckle workbook dataset salesforce soql preview --credential-id <credential-id> --file /absolute/path/contacts.soql --json
freckle workbook dataset salesforce create <workbook-id> --label "SF Contacts" --credential-id <credential-id> --soql-file /absolute/path/contacts.soql --request-id <stable-request-id>
freckle workbook dataset salesforce inspect <workbook-id> <source-id>
freckle workbook dataset salesforce run-again <workbook-id> <source-id> --request-id <stable-request-id>
freckle workbook dataset salesforce schedule set <workbook-id> <source-id> --schedule '<cron>' --time-zone '<IANA-zone>'
freckle workbook dataset salesforce schedule remove <workbook-id> <source-id>
```

## Field catalogs

The field catalog names the Dataset fields that render as columns and map into workflow inputs. Format (`--file catalog.json`):

```json
[{ "id": "email", "path": "/email", "label": "Email", "type": "string", "visible": true, "order": 0 }]
```

Types: `string`, `number`, `boolean`, `json`. An empty catalog is seeded from the first field-bearing write; once non-empty, ingestion never changes it — edits are explicit:

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
```

`connection create` requires an active Workflow with a published revision, creates the output Dataset, and returns `outputDatasetId` — keep both ids. Add `--unfold-output-id <outputId>` to make each element of one array-of-objects output its own row.

### Input mappings

```json
{
  "email": { "kind": "field", "fieldId": "email" },
  "region": { "kind": "constant", "value": "EMEA" }
}
```

Keys are the workflow's input ids (`shape` on `workflow saved list`); `fieldId` is a catalog id on the input Dataset. The mapping is re-checked against the workflow's current contract at every trigger.

### Pending and triggering

An entry is **pending** for a connection when its current version has no recorded run for that connection — new entries, updated entries, and upserted entries all pend; admitting a run un-pends that version.

- A manual `trigger` admits pending entries oldest-first (by entry creation), at most 1,000 per call (`--limit 1..1000` to admit fewer, e.g. a sample of the first rows). Loop until `startedCount` is 0 to drain a large Dataset.
- `--trigger-policy auto` starts runs as entries become pending. Switching a connection to auto does **not** catch up already-pending entries — trigger manually first, then flip.
- Failed runs never retry automatically. `rerun-failed` re-runs failed current-version entries, reusing their ledger records (no retry history).
- `runs` pages the ledger: each record binds one input entry version to one Workflow run, with status (`running`/`completed`/`failed`/`discarded`) and failure detail.

### Explicit entry runs

`connection run` sends 1–1,000 entry ids and returns one result per id: `started`/`rerun` (accepted, with run ids), `skipped` (active run exists), `rejected` (`not_found` / `wrong_dataset`), or `failed` (stable admission failure with `reason`). A mixed response is a success — inspect every result. Results report **acceptance, not completion**; follow accepted runs with `connection runs` or `workflow saved runs watch`. Connections are live bindings: each run uses the latest published revision.

Each successful run upserts output entries keyed to the input entry (lineage in `producedByRunId`, `producedFromEntryId`, `producedFromEntryVersion`); a failed run writes nothing.

## Limits and workarounds

- A connection's mapping, unfold config, and output label cannot be edited, and connections cannot be deleted. To change a mapping: create a new connection on the same input Dataset (allowed — one Dataset can feed many connections), which creates a fresh output Dataset; leave the old connection on `manual` and it stays inert.
- The CLI cannot rename or unarchive a Dataset; a Dataset can be hard-deleted only while no connection references it.
- No CSV export; read output entries with `dataset entry list`.
- An input Dataset may feed many connections, and a connection never crosses Workbooks.
- Archived Workbooks/Datasets refuse ingestion and triggers; archiving a Workbook starts asynchronous Signal cleanup, and unarchiving does not recreate its Signals.
