# Provider-backed lists

A List is a Workbook whose Dataset is filled by a provider search. List tools own pagination, checkpoints and resume. Do not build a Workflow merely to perform the initial search import.

| Provider/entity | Preview tool | Create tool | Meaning and cost |
| --- | --- | --- | --- |
| Apollo companies | `listBuilds_previewCompanies` | `listBuilds_createCompanies` | Technology/keywords/revenue; normalized company records; per non-empty provider page |
| Apollo people | `listBuilds_previewPeople` | `listBuilds_createPeople` | Direct people search. Set `mode` to basic or enriched; basic is free and names may be obfuscated; enriched bills per successfully stored person |
| AI Ark companies | `listBuilds_previewAIArkCompanies` | `listBuilds_createAIArkCompanies` | Lookalike domains, industry/founded year and smart matching; rich company fields; per non-empty page |
| AI Ark people | `listBuilds_previewAIArkPeople` | `listBuilds_createAIArkPeople` | Rich profile/current company; per returned person; always preview first |

Read the selected tool's payload schema; preserve every include/exclude/range/nested filter. Provider filter references are in [list/](list/apollo-companies.md). Pin provider, entity, filters, requested count and create-only versus run intent. Pick a descriptive name and one-line description. If no provider is specified, explain relevant differences and recommend one.

Present one compact filter/cost table and one combined choice: preview first (recommended), or the immediate action consistent with the user's run intent. Apollo people also needs an explicit basic/enriched choice. A vague yes that resolves neither choice is insufficient. AI Ark people only offers preview initially. A user-directed filter revision plus preview intent authorizes that revised preview immediately.

Preview uses the approved filters and requested import limit. Show every returned compact example, returned `totalEntries`, and `estimatedCreditCost`; for AI Ark people also show `requestedEntries`. These totals mean different things: full provider match count may exceed the 50,000 import cap; requested count limits import; display page size limits neither. Never recalculate the returned estimate from vendor pricing. Company imports charge per committed non-empty page of up to 100; empty pages cost nothing. Enriched Apollo's limit caps candidates, so enrichment misses can reduce stored count. Possible contact fields are not guaranteed.

After preview, get informed approval for creation/import. Preview-only approval never authorizes full import. Use the create tool with the exact approved payload; then `listBuilds_run` with `params.workbookId` and a stable `payload.requestId` if run intent is authorized. Retain that ID through retries/handoffs. Creation is not generally idempotent: inspect for the Workbook after uncertainty rather than creating again.

Poll `listBuilds_get` while queued/running; stop at completed/failed. Report only returned progress and public failures. Read the returned Dataset using `datasets_listDatasetEntries` and its cursor/compact projection. Reconcile actual imported count, then deliver the returned Workbook URL.

Offer relevant follow-ups: people email/phone/profile enrichment, scoring or delivery; companies people-finding, enrichment, scoring or Signals. A chosen follow-up is existing-target REFINE work: use a connection that writes a separate output Dataset, preserve the imported Dataset, and apply the sample gate. Research Agent cannot reliably recover contact email/phone from the open web.
