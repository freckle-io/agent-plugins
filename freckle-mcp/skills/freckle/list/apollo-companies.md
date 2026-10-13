# Apollo Companies

Read `listBuilds_previewCompanies` and the corresponding create tool schema. Preserve approved filters exactly. Preview and mode approval rules live in [LIST.md](../LIST.md).

## Filter payload

Supply the complete `payload.filters` object. Advanced fields include `companyIds`, multiple `employeeCountRanges`, `latestFundingAmount`, `totalFundingAmount`, `latestFundingDate`, `jobTitles`, `jobLocations`, `openJobCount`, and `jobPostedDate`. Employee-count ranges require both `min` and `max`. Money and other count ranges need at least one bound with `min <= max`; date ranges use `YYYY-MM-DD` `from`/`to` with at least one bound. For example:

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
