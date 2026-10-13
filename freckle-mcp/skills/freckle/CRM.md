# CRM imports

Choose an authorized provider credential from `integrationCredentials_list`. Preserve object types, selected fields and nested selection semantics. Import permission does not authorize enrichment, recurring schedules or CRM writes unless requested.

## HubSpot

`hubspotDatasetSources_create` creates a Dataset/source and starts its first import. Select contacts, companies or deals; 1–200 unique properties in the desired order; and exactly one selection mode: stable list ID, all records, or filter groups. Filters within each group are ANDed and groups ORed. Preserve the full JSON shape. Supported operators and payload unions are in the tool schema. The limits are 1–5 groups, 1–6 filters/group, 18 filters total.

Use an operation-specific stable requestId for create/runAgain: same ID in the same scope recovers the original operation; a new import gets a new ID. `hubspotDatasetSources_get` returns config, schedule and latestRun. In an immediate create/runAgain response, the top-level run is authoritative; nested source.latestRun may still be old. Poll pending/running to completed/failed and inspect errors/counts.

Scheduling uses `hubspotDatasetSources_setSchedule` with cron and IANA timezone together (minimum 10 minutes); deleteSchedule stops future imports. runAgain does not alter a schedule. Lists support scheduling and become incremental after the initial import.

## Salesforce

Discover first with `salesforceDatasetSources_objects`, `_fields`, and `_listViews`. `salesforceDatasetSources_create` makes a Dataset/source. Without a schedule it starts import; with a schedule it only creates the scheduled source. Choose exactly one list view, incremental new objects (optional supported backfill window), or custom SOQL. Use 1–200 direct fields, stable requestId and paired cron/timezone.

For custom SOQL, call `salesforceDatasetSources_previewSoql` with the exact query string before create. Inspect object, fields, effective SOQL and up to ten rows. Revise until valid and appropriate; zero matches is a valid preview but may not meet the goal. Importer owns ORDER BY/LIMIT/OFFSET; aggregate/grouped/relationship-select/alias/function/subquery shapes are rejected. Do not invent unsupported query workarounds.

Inspect and poll with `salesforceDatasetSources_get`; runAgain, setSchedule and deleteSchedule mirror their HubSpot purposes. Reimports update matching logical records; records no longer returned remain in the Dataset. Report actual Dataset counts and source/run status.
