# AI Ark Companies

The primary command is:

```bash
freckle list build ai-ark companies \
  --name "India Software Companies" \
  --description "Software companies in India that match the approved prospecting criteria" \
  --location "India" \
  --industry "Software Development" \
  --min-employees 101 \
  --max-employees 500 \
  --limit 1000
```

Available inline filters are repeatable `--lookalike-domain`, `--domain`, `--location`, `--industry`, `--keyword`, and `--technology`; `--company-name`; paired `--min-employees` and `--max-employees`; paired `--min-revenue` and `--max-revenue`; and paired `--min-founded-year` and `--max-founded-year`. `--lookalike-domain` accepts at most 5 values. AI Ark's page/import maximum is 50,000 companies and `--limit` accepts 1–50,000. When `--limit` is omitted, AI Ark imports all provider matches up to the 50,000-entry cap.

Inline name, industry, keyword, and technology filters use the command's common AI Ark smart-match defaults. Use `--search-file` for precise any/all, include/exclude, match-mode, keyword-source, multiple-range, or `advancedAccountFilters` JSON. The file contains the complete AI Ark `filters` object with optional `lookalikeDomains`, `account`, and `advancedAccountFilters`; a search file and inline flags remain alternative styles.

AI Ark preview returns up to 10 normalized companies with every available field except `technologies`, in stable table columns or JSON.

## Cost line

Company Search bills 1.8 credits per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `1.8 × ceil(requested limit ÷ 100)` credits; with no limit, the preview estimates `1.8 × ceil(min(totalEntries, 50,000) ÷ 100)` credits.

## Completed entries

For a completed AI Ark company list, use `workbook dataset entry list <workbook-id> <dataset-id> --ai-ark-companies --limit 100`; this API-backed projection retains every available company field except the potentially large `technologies` array in both table and `--json` output, while the stored Dataset Entry remains complete. Follow `nextCursor` pages.
