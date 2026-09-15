# Apollo People

Read `freckle list build apollo people --help` (or `people enriched --help`) for command syntax. Mode selection and approval rules live in [List building](../LIST.md#apollo-people-mode). Load this reference for advanced filters or a search inside a Workflow.

## Search file

For fields with no inline flag, write the complete Apollo people `filters` object to an absolute `.json` path and pass `--search-file <path>`; the file and inline filter flags are mutually exclusive. Search-file-only fields are `companyIds`, `companyEmployeeCountRanges`, `companyRevenue`, and `includeSimilarTitles`; `--strict-titles` equals `includeSimilarTitles: false`. For example:

```json
{
  "titles": ["Revenue Operations"],
  "companyEmployeeCountRanges": [{ "min": 101, "max": 500 }],
  "companyRevenue": { "min": 1000000 },
  "includeSimilarTitles": false
}
```

## Workflow node route

When the search belongs inside a larger Workflow rather than directly filling a List, read [Apollo Find People](../workflow/apollo-find-people.md), inspect the selected `apolloFindPeopleBasic` or `apolloFindPeople` contract, pin its returned version, and author the search from the approved filters. Push handoff results to a dedicated Dataset in the same Workbook. The basic node calls only Apollo search and is free; the enriched node searches and then bulk-enriches its matches. If the Workflow runs once for the whole search, the normal ten-input-row connection sample gate does not apply; if it runs from Dataset inputs, follow [WORKBOOKS.md#pending-and-triggering](../WORKBOOKS.md#pending-and-triggering) and show the Credit Forecast Summary from [credit-cost.md](../workflow/credit-cost.md).
