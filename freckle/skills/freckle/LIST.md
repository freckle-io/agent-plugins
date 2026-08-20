# List Building

A List is a Workbook whose Dataset is filled by a backend-owned import from a provider search. The backend owns search paging, imports, checkpoints, and resume behavior. Drive it with `list` commands; do not assemble a Workflow or Dataset connection for the import itself — the [enriched people follow-up](#enriched-people-follow-up) adds them afterwards.

## Providers

| Provider | Entity | Build command | Filters and preview |
| --- | --- | --- | --- |
| AI Ark | companies | `freckle list build ai-ark companies` | [AI Ark companies](#ai-ark-companies) |
| AI Ark | people | `freckle list build ai-ark people` | [AI Ark people](#ai-ark-people) |
| Apollo | companies | `freckle list build apollo companies` | [Apollo companies](#apollo-companies) |
| Apollo | people | `freckle list build apollo people` | [Apollo people](#apollo-people) |

Every provider follows the same lifecycle below; the provider's section owns its filter vocabulary, constraints, and preview shape.

## Pin the request

Resolve and pin the org by the shared rules in [SKILL.md](SKILL.md#shared-operating-rules). Before creating anything, pin:

- the list name;
- the Workbook description;
- the provider and entity from the table above;
- every provider filter;
- the requested entry limit; and
- whether the user wants provider work to start after creation.

Show those choices in a compact filter table that includes the cost line from the provider's section. Ask for plan approval and the preview-or-create choice in one response. Recommend previewing 10 matching entries and give exactly these two selectable replies:

- `approve and preview` **(recommended)** — approve this exact plan and preview 10 matching entries; and
- one immediate-action label matching the pinned run intent: `approve and create` when the pinned run intent is create-only, or `approve, create, and run` when the pinned run intent includes starting the import.

A sufficient response unambiguously names either `approve and preview` or the one immediate-action label shown. When the response names neither label, keep the gate open and ask the user to reply with one of them. If the user revises the plan, show the revised table and the same combined choice again. Preview, creation, and provider work wait for this combined approval. `list inspect` is read-only and can run before approval when the user names an existing List Workbook.

AI Ark people always follows its command's preview-first path. For that provider/entity, offer `approve and preview` as the only initial action; creation and run choices wait for the returned preview.

## Build

Compose the build command from the provider's section — its example command, filters, and constraints are authoritative. `--name`, `--description`, `--limit`, `--preview`, `--run-request-id`, and `--run` are shared build flags for every provider. Creation requires a non-blank plain-language Workbook description; pass the approved value with `--description`. Preview creates no Workbook and does not require it. Never combine `--preview` with `--run`.

For the advanced backend filter shape, write the `filters` object accepted by the provider's command to an absolute `.json` path and pass `--search-file <path>`. A search file and inline filter flags are alternative inputs; use exactly one style. AI Ark people additionally accepts the same complete filter object as inline JSON through `--input`.

Creation is not idempotent. If its transport outcome is uncertain, do not repeat the build command until you confirm whether the named Workbook was created. When creation also uses `--run`, use a stable `--run-request-id` and keep it until the run outcome is certain.

## Approved preview or immediate creation

The immediate-action label authorizes only the pinned create-only or create-and-run intent named by that label. For `approve and preview`, run the exact approved filters and requested `--limit` with `--preview`. Preview makes one synchronous, server-sized provider search and creates no Workbook, Dataset, Dataset Source, or import run. Show every returned normalized entry in a compact Markdown table. For Apollo and AI Ark, show the returned `totalEntries` and `estimatedCreditCost`: `totalEntries` is the provider's full matching total independent of the requested limit and can exceed the 50,000-entry import cap; `estimatedCreditCost` is the backend-calculated customer-facing cost for the requested limit. Use both returned values directly; do not recalculate them.

After showing the approved preview, ask for informed approval before full creation or import. Offer an explicit action label matching the already-pinned run intent—`create list` for create-only or `create and run` for starting the import—plus `stop`. Only after that post-preview approval, run the approved build command without `--preview`, adding `--run` and a stable `--run-request-id` for `create and run`. On `stop`, end the route without creating the list.

CLI-generated run request IDs are retry-stable, but explicit IDs make an agent handoff reproducible.

## Run and inspect

Create without `--run` returns the backend's `not_started` status. Start an approved existing build with:

```bash
freckle list run <workbook-id> --request-id <stable-run-id>
```

Inspect progress with:

```bash
freckle list inspect <workbook-id>
```

Poll while status is `queued` or `running`. Stop on `completed` or `failed`. Report the returned `requestedEntries`, `importedEntries`, `currentPage`, `nextPage`, and public `failure` exactly as returned; do not infer intermediate progress or invent provider states.

AI Ark reports `currentPage` and `nextPage` as zero-based provider page indexes. Apollo preserves its existing one-based checkpoint reporting. In both cases, print the returned values without conversion.

For a completed Apollo list, use the returned `datasetId` with `workbook dataset entry list <workbook-id> <dataset-id> --limit 100` and follow `nextCursor` pages. For a completed AI Ark company list, use `workbook dataset entry list <workbook-id> <dataset-id> --ai-ark-companies --limit 100`; this API-backed projection retains every available company field except the potentially large `technologies` array in both table and `--json` output, while the stored Dataset Entry remains complete. Follow `nextCursor` pages. The created asset handed to the user is the Workbook:

`[<list name>](https://next.freckle.io/workbooks/<workbook-id>)`

## Apollo companies

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

Company Search bills one page charge per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `ceil(requested limit ÷ 100)` page charges; with no limit, the preview estimates `ceil(min(totalEntries, 50,000) ÷ 100)` page charges. State that structure in the plan's cost line. Quote a credit figure only from the backend: show its `estimatedCreditCost` rather than pricing the page charge yourself.

## AI Ark companies

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

Available inline filters are repeatable `--lookalike-domain`, `--domain`, `--location`, `--industry`, `--keyword`, and `--technology`; `--company-name`; paired `--min-employees` and `--max-employees`; paired `--min-revenue` and `--max-revenue`; and paired `--min-founded-year` and `--max-founded-year`. `--lookalike-domain` accepts at most 5 values. AI Ark's page/import maximum is 50,000 companies, `--limit` accepts 1–50,000, and preview returns up to 10 normalized companies. When `--limit` is omitted, AI Ark imports all provider matches up to the 50,000-entry cap.

Inline name, industry, keyword, and technology filters use the command's common AI Ark smart-match defaults. Use `--search-file` for precise any/all, include/exclude, match-mode, keyword-source, multiple-range, or `advancedAccountFilters` JSON. The file contains the complete AI Ark `filters` object with optional `lookalikeDomains`, `account`, and `advancedAccountFilters`; a search file and inline flags remain alternative styles.

AI Ark preview returns every available normalized company field except `technologies`, in stable table columns or JSON, plus the provider-reported `totalEntries` and backend-calculated `estimatedCreditCost`. Company Search bills 1.8 credits per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `1.8 × ceil(requested limit ÷ 100)` credits; with no limit, the preview estimates `1.8 × ceil(min(totalEntries, 50,000) ÷ 100)` credits. Report both returned fields directly, using the backend estimate rather than recalculating it.

## AI Ark people

Use AI Ark People Search directly for rich base profiles and their nested current-company data. For example:

```bash
freckle list build ai-ark people \
  --name "India RevOps Leaders" \
  --description "Revenue Operations leaders at software companies in India" \
  --title "Revenue Operations" \
  --location "India" \
  --company-industry "Software Development" \
  --limit 1000 \
  --run
```

Available inline contact filters are repeatable `--full-name`, `--linkedin-url`, `--location`, `--title`, `--seniority`, `--skill`, and `--profile-badge`. Current-company filters are repeatable `--company-domain`, `--company-location`, and `--company-industry`, plus paired `--min-employees` and `--max-employees`. Inline text filters use AI Ark smart matching. `--limit` accepts 1–50,000 people and defaults to 100.

Use `--input '<json>'` or `--search-file <path>` for the complete product filter object with optional `account`, `contact`, `advancedAccountFilters`, and `advancedContactFilters`. Inline flags, `--input`, and `--search-file` are three alternative input styles; preserve the approved nested object exactly.

The command always previews up to 10 people before creation. Its default table and JSON previews contain only `id`, `fullName`, `title`, `company`, `location`, and `linkedin` for each person, plus the provider's full `totalEntries`, the requested import count as `requestedEntries`, and the API-returned customer-facing `estimatedCreditCost`. Show all three totals directly. Use `--raw` only when the complete provider preview records are explicitly needed; it does not change the full records written by the import. The API currently returns `estimatedCreditCost: 0` until a canonical Freckle pricing rule exists; do not describe People Search as free or substitute provider-side pricing.

After the skill's post-preview approval, rerun the exact command without `--preview` and add `--yes`; add `--run` and a stable `--run-request-id` only for approved create-and-run intent. `--yes` bypasses the CLI prompt, not the user approval gate. A decline or `stop` ends without creating resources. This List contains the base People Search payload only: Email Finder and mobile finder are separate future enrichments and stay out of this command.

Completed AI Ark people entries retain the full person and nested company payload. List a compact read-only view with `freckle workbook dataset entry list <workbook-id> <dataset-id> --ai-ark-people`; add `--json` for compact structured values and follow `nextCursor` pages. Omit `--ai-ark-people` only when the complete stored Dataset Entry payload is explicitly needed.

## Apollo people

Use Apollo People Search directly; do not search for companies first. For example:

```bash
freckle list build apollo people \
  --name "San Francisco RevOps People" \
  --description "Revenue Operations leaders in San Francisco for outbound prospecting" \
  --title "RevOps" \
  --location "San Francisco" \
  --limit 1000
```

Available inline filters are repeatable `--title`, repeatable `--location`, repeatable `--excluded-title`, repeatable `--excluded-location`, repeatable `--seniority`, `--keyword`, repeatable `--company-domain`, repeatable `--company-location`, and `--strict-titles`. Apollo expands similar titles by default; `--strict-titles` disables that expansion. `--limit` accepts 1–50,000 people and defaults to 100.

People Search returns search-only prospect records. The people cost line is a mode choice; show both modes with the plan table. For people, a sufficient combined-gate reply names both a mode and a label; when either is missing, keep the gate open and ask for the missing piece:

- `basic` — the List's Dataset shows first name, an obfuscated last name such as `J********`, job title, and company name. This import costs 0 credits and records no Freckle credit usage.
- `enriched` — the same basic List plus the [enriched people follow-up](#enriched-people-follow-up); costs the `apolloEnrichPerson` catalog `creditCost` per person Apollo successfully finds (a person the node cannot find costs nothing), so one enrichment pass costs at most that price × imported rows. Read the current price with `freckle workflow node inspect apolloEnrichPerson` before quoting it. Fields such as full last name, LinkedIn URL, email address, and company domain are returned only when Apollo has them — present them as possible outcomes, never promised columns.

The enrichment Workflow enters only through the `enriched` choice or a later explicit user request via [REFINE.md](REFINE.md).

Apollo's preview returns 10 normalized people showing the basic fields only — name with an obfuscated last name, title, and organization — and costs 0 credits.

### Enriched people follow-up

Run the basic route above to `completed` first and note `importedEntries` — the inspected per-person price caps one pass at that count. Then follow [REFINE.md](REFINE.md) against the created List Workbook: inspect the node contract first (`workflow node inspect apolloEnrichPerson`), author a Workflow whose provider node is `apolloEnrichPerson@<inspected-version>` (pin the version the inspect returns) with a Workflow input bound to the node's `personId` port, connect the List's Dataset as the connection input mapping the hidden `Apollo person ID` field (`apollo-id`, row path `/id`) to that input, and let the connection write results to its own separate output Dataset — the basic List Dataset is never modified. Run through the sample gate: trigger the first 10 rows (`--limit 10` — [WORKBOOKS.md#pending-and-triggering](WORKBOOKS.md#pending-and-triggering)), show their terminal results with the Credit Forecast Summary ([credit-cost.md](workflow/credit-cost.md)), and ask before running the rest.

**Completion** — every box checked:

- [ ] One unambiguous initial response approved the org, list name, provider, filters, requested limit, and run intent and selected either the recommended 10-entry preview or the one immediate action matching that run intent.
- [ ] The exact approved filters were sent with `--preview` only after `approve and preview`; every returned compact preview entry, `totalEntries`, and `estimatedCreditCost` were shown.
- [ ] After a preview, an explicit `create list` or `create and run` response approved full creation or import; `stop` ended the route without creation.
- [ ] Immediate creation followed only the combined gate's run-intent-specific label; post-preview creation followed only the distinct informed approval.
- [ ] Every run used a stable request ID retained through any uncertain transport outcome, and no uncertain create was repeated before checking for its Workbook.
- [ ] Every started import reached `completed` or `failed`, and only returned status, progress, and public failure fields were reported.
- [ ] Completed results were inspected from the returned Dataset and the created Workbook was linked.
- [ ] For Apollo people, the combined gate resolved the `basic` or `enriched` choice explicitly before creation, and an `enriched` choice followed the enriched people follow-up through the sample gate.
