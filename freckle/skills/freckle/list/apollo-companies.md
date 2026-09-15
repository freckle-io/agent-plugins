# Apollo Companies

Read `freckle list build apollo companies --help` for command syntax, inline filters, industry values, and defaults. Load this reference when the approved filters need a search file.

## Search file

For fields with no inline flag, write the complete Apollo `filters` object to an absolute `.json` path and pass `--search-file <path>`; the file and inline filter flags are mutually exclusive. Search-file-only fields are `companyIds`, multiple `employeeCountRanges`, `latestFundingAmount`, `totalFundingAmount`, `latestFundingDate`, `jobTitles`, `jobLocations`, `openJobCount`, and `jobPostedDate`. Employee-count ranges require both `min` and `max`. Money and other count ranges need at least one bound with `min <= max`; date ranges use `YYYY-MM-DD` `from`/`to` with at least one bound. For example:

```json
{
  "industries": ["computer_software"],
  "employeeCountRanges": [
    { "min": 1, "max": 50 },
    { "min": 5001, "max": 10000 }
  ],
  "latestFundingDate": { "from": "2025-01-01" },
  "jobTitles": ["Revenue Operations"]
}
```
