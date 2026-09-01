# AI Ark People

Use AI Ark People Search directly for rich base profiles and their nested current-company data. Preview first:

```bash
freckle list build ai-ark people \
  --name "India RevOps Leaders" \
  --description "Revenue Operations leaders at software companies in India" \
  --title "Revenue Operations" \
  --location "India" \
  --company-industry "Software Development" \
  --limit 1000 \
  --preview --json
```

Available inline contact filters are repeatable `--full-name`, `--linkedin-url`, `--location`, `--title`, `--seniority`, `--skill`, and `--profile-badge`. Current-company filters are repeatable `--company-domain`, `--company-location`, and `--company-industry`, plus paired `--min-employees` and `--max-employees`. `--full-name`, `--title`, `--skill`, and `--company-industry` use AI Ark smart matching; the other inline filters match exactly. `--seniority` accepts `founder`, `owner`, `partner`, `c_suite`, `vp`, `director`, `head`, `manager`, `senior`, `mid-level`, `entry`, and `intern`. `--profile-badge` accepts `VERIFIED`, `PREMIUM`, `OPEN_TO_WORK`, `INFLUENCER`, `CREATOR`, and `HIRING`. `--limit` accepts 1–50,000 people and defaults to 100.

Use `--input '<json>'` or `--search-file <path>` for the complete product filter object with optional `account`, `contact`, `advancedAccountFilters`, and `advancedContactFilters`. Inline flags, `--input`, and `--search-file` are three alternative input styles; preserve the approved nested object exactly.

## Preview and cost line

The command always previews up to 10 people before creation. Its default table and JSON previews contain only `id`, `fullName`, `title`, `company`, `location`, and `linkedin` for each person, plus the provider's full `totalEntries`, the requested import count as `requestedEntries`, and the customer-facing `estimatedCreditCost`. Show all three totals directly. Use `--raw` only when the complete provider preview records are explicitly needed; it does not change the full records written by the import. Report the `estimatedCreditCost` the command prints; do not substitute provider-side pricing.

After the skill's post-preview approval, rerun the exact command without `--preview` and add `--yes`; the command previews again before it creates. Add `--run` and a stable `--run-request-id` only for approved create-and-run intent:

```bash
freckle list build ai-ark people \
  --name "India RevOps Leaders" \
  --description "Revenue Operations leaders at software companies in India" \
  --title "Revenue Operations" \
  --location "India" \
  --company-industry "Software Development" \
  --limit 1000 \
  --yes --run --run-request-id "india-revops-import-1"
```

`--yes` bypasses the CLI prompt, not the user approval gate; non-interactive shells fail without it. A decline or `stop` ends without creating resources. This List contains the base People Search payload only: Email Finder and mobile finder are separate future enrichments and stay out of this command.

## Completed entries

Completed AI Ark people entries retain the full person and nested company payload. List a compact read-only view with `freckle workbook dataset entry list <workbook-id> <dataset-id> --ai-ark-people`; add `--json` for compact structured values and follow `nextCursor` pages. Omit `--ai-ark-people` only when the complete stored Dataset Entry payload is explicitly needed.
