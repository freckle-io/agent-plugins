# Apollo Companies

The primary command is:

```bash
freckle list build apollo companies \
  --name "San Francisco Companies" \
  --description "Companies in San Francisco that match the approved prospecting criteria" \
  --location "San Francisco" \
  --min-employees 101 \
  --max-employees 500 \
  --limit 1000
```

Available inline filters are `--company-name`, repeatable `--domain`, repeatable `--location`, repeatable `--excluded-location`, `--min-employees`, `--max-employees`, repeatable `--technology`, repeatable `--keyword`, `--min-revenue`, and `--max-revenue`. Always supply `--min-employees` and `--max-employees` together because Apollo accepts only bounded employee-count ranges; search-file `employeeCountRanges` likewise require both `min` and `max`. `--limit` accepts 1–50,000 companies. When omitted, Apollo imports all provider matches up to the 50,000-entry import cap.

## Search file

For fields with no inline flag, write the complete Apollo `filters` object to an absolute `.json` path and pass `--search-file <path>`; the file and inline filter flags are mutually exclusive. Search-file-only fields are `companyIds`, multiple `employeeCountRanges`, `latestFundingAmount`, `totalFundingAmount`, `latestFundingDate`, `jobTitles`, `jobLocations`, `openJobCount`, and `jobPostedDate`. Money and count ranges need at least one bound with `min <= max`; date ranges use `YYYY-MM-DD` `from`/`to` with at least one bound. For example:

```json
{
  "employeeCountRanges": [
    { "min": 1, "max": 50 },
    { "min": 5001, "max": 10000 }
  ],
  "latestFundingDate": { "from": "2025-01-01" },
  "jobTitles": ["Revenue Operations"]
}
```

Apollo's preview returns up to 10 normalized companies.

## Cost line

Company Search bills one page charge per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `ceil(requested limit ÷ 100)` page charges; with no limit, the preview estimates `ceil(min(totalEntries, 50,000) ÷ 100)` page charges. State that structure in the plan's cost line. Quote the `estimatedCreditCost` the preview command prints rather than pricing the page charge yourself.
