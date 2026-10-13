# Build with Freckle

The normal deliverable is a Workbook with input Dataset → saved Workflow → output Dataset. A request explicitly scoped to a Workflow artifact can omit input ingestion and connection creation; Push to Dataset still requires its destination and readers to be understood.

## Data-import fast lane

For pure ingestion into a new Workbook, settle only missing key/destination questions. Choose labels, call `workbooks_createWorkbook`, then `datasets_createWorkbookDataset`, then `datasets_importDatasetCsv` with parsed `filename`, `headers`, `keyColumn`, and `rows`. Read `datasets_listDatasetEntries` to verify counts and representative rows. Report the returned Workbook URL and actual imported count, then stop. A stable key prevents duplicate logical records on re-import. This sequence is not an atomic transaction: inspect any ambiguous failure; clean up only a newly-created empty Dataset when appropriate. Existing destinations route through REFINE.

## Gated build path

For new processing designs, track these six steps and read each reference when entering it:

1. [Pick a workspace](steps/step-1-context.md).
2. [Nail down the goal](steps/step-2-objective.md): inspect reuse and resolve shape-changing questions.
3. [Scout nodes and map data](steps/step-3-contract-map.md): inspect contracts and credit costs.
4. [Sign off on the plan](steps/step-4-plan.md): Workbook picture, provider-level branches, mappings, result fields, credit maximum, and run intent.
5. [Set up and build](steps/step-5-draft.md): create the approved artifacts and compile to `ok: true`.
6. [Wire and run](steps/step-6-run.md): connect, admit the approved sample, inspect results and cost before expanding.

The approved shape is binding. Provider substitutions, removed fallbacks, changed output semantics, or different destinations require revisiting the affected decision. Collectors/switches that faithfully implement the shape are implementation choices. Existing-target operational edits use REFINE; they do not restart this design ceremony.
