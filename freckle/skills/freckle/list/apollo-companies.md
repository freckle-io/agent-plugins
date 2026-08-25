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

Apollo's preview returns 10 normalized companies.

## Cost line

Company Search bills one page charge per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `ceil(requested limit ÷ 100)` page charges; with no limit, the preview estimates `ceil(min(totalEntries, 50,000) ÷ 100)` page charges. State that structure in the plan's cost line. Quote a credit figure only from the backend: show its `estimatedCreditCost` rather than pricing the page charge yourself.
