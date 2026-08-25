# Apollo People

Use Apollo People Search directly; do not search for companies first. For example:

```bash
freckle list build apollo people \
  --name "San Francisco RevOps People" \
  --description "Revenue Operations leaders in San Francisco for outbound prospecting" \
  --title "RevOps" \
  --location "San Francisco" \
  --limit 1000
```

That command builds a Basic List. Add the positional `enriched` mode when the List itself must contain enriched people:

```bash
freckle list build apollo people enriched \
  --name "Enriched San Francisco RevOps People" \
  --description "Enriched Revenue Operations leaders in San Francisco for outbound prospecting" \
  --title "RevOps" \
  --location "San Francisco" \
  --limit 1000
```

Available inline filters are repeatable `--title`, repeatable `--location`, repeatable `--excluded-title`, repeatable `--excluded-location`, repeatable `--seniority`, `--keyword`, repeatable `--company-domain`, repeatable `--company-location`, and `--strict-titles`. Apollo expands similar titles by default; `--strict-titles` disables that expansion. `--limit` accepts 1–50,000 people and defaults to 100.

## Cost line

The people cost line is a mode choice; show both modes with the plan table and weave the mode question into the combined gate's one natural question. A sufficient combined-gate reply picks both a mode and a path; when either is missing, keep the gate open and ask for the missing piece:

- `basic` — use `freckle list build apollo people`. Results show first name, an obfuscated last name such as `J********`, job title, and company name. This import costs 0 credits and records no Freckle credit usage.
- `enriched` — use `freckle list build apollo people enriched`. The import searches and then bulk-enriches the candidates, stores only people Apollo successfully enriches, and bills the current backend price once per stored enriched person. A candidate Apollo cannot enrich is neither stored nor billed. Fields such as full last name, LinkedIn URL, email address, and company domain are returned only when Apollo has them — present them as possible outcomes, never promised columns.

The enriched command is a direct List import, not a Workflow follow-up: do not create a Basic List first and do not try to enrich imported Apollo IDs one at a time. Its `--limit` caps search candidates, so failed enrichments can make the final `importedEntries` lower than the requested limit.

Apollo's preview returns 10 normalized search-only people showing name with an obfuscated last name, title, and organization. Preview costs 0 credits in either mode. For Enriched, report the returned `estimatedCreditCost` as the maximum for the requested candidate limit; actual usage follows the enriched people the import returns and can be lower.

## Workflow node route

When the search belongs inside a larger Workflow rather than directly filling a List, read [Apollo Find People](../workflow/apollo-find-people.md), inspect the selected `apolloFindPeopleBasic` or `apolloFindPeople` contract, pin its returned version, and author the search from the approved filters. Push handoff results to a dedicated Dataset in the same Workbook. The basic node calls only Apollo search and is free; the enriched node searches and then bulk-enriches its matches. If the Workflow runs once for the whole search, the normal ten-input-row connection sample gate does not apply; if it runs from Dataset inputs, follow [WORKBOOKS.md#pending-and-triggering](../WORKBOOKS.md#pending-and-triggering) and show the Credit Forecast Summary from [credit-cost.md](../workflow/credit-cost.md).
