# List Building

A List is a Workbook whose Dataset is filled by an import from a provider search. The `list` commands manage the whole import, including search paging, checkpoints, and resume; do not assemble a Workflow or Dataset connection for the import itself — follow-ups come afterwards through [From List to Workbook](#from-list-to-workbook).

## Providers

Every provider follows the same lifecycle below. Each provider guide owns its example command, filter vocabulary, constraints, preview shape, and cost line — load the pinned provider's guide before composing any build or preview command.

| Provider | Entity | Build command | Stands out for | Each imported row holds | Cost shape | Guide |
| --- | --- | --- | --- | --- | --- | --- |
| Apollo | companies | `freckle list build apollo companies` | technology and keyword targeting, revenue ranges | a normalized company record | billed per non-empty search page | [Apollo companies](list/apollo-companies.md) |
| Apollo | people | Basic: `freckle list build apollo people`; Enriched: `freckle list build apollo people enriched` | title, seniority, and location prospecting with a Basic or Enriched mode | a search-only prospect or a successfully enriched person, depending on the command | free Basic import; Enriched billed per returned person | [Apollo people](list/apollo-people.md) |
| AI Ark | companies | `freckle list build ai-ark companies` | lookalike-domain search, industry and founded-year filters, smart matching | every available company field, including technologies | billed per non-empty search page | [AI Ark companies](list/ai-ark-companies.md) |
| AI Ark | people | `freckle list build ai-ark people` | skill, seniority, and profile-badge filters with smart matching | a rich full profile with nested current-company data at import time | billed per returned person | [AI Ark people](list/ai-ark-people.md) |

When the request names no provider, present the matching entity rows from this table in plain language and recommend one inside the batch grill — the "Stands out for", row-contents, and cost-shape differences are the decision material.

## Pin the request

Resolve the org by the shared rules in [SKILL.md](SKILL.md#shared-operating-rules). Before creating anything, pin:

- the list name;
- the Workbook description;
- the provider and entity from the table above;
- every provider filter;
- the requested entry limit; and
- whether the user wants provider work to start after creation.

Show those choices in a compact filter table that includes the cost line from the provider's guide. Ask for plan approval and the preview-or-create choice in one response, phrased as one natural question a colleague would ask — the two paths woven into the sentence, the recommendation stated in passing, and an open invitation to tweak the plan. The question offers two paths:

- **preview first (recommended)** — approve this exact plan and preview up to 10 matching entries before committing to the full import; and
- the one immediate action matching the pinned run intent — create the list now when the pinned run intent is create-only, or create it and start the import when the pinned run intent includes starting the import.

For example: "Want me to pull a quick preview of up to 10 matches first — that's what I'd do — or create the list and import all 1,000 right away? If anything in the plan needs a tweak, just say the word." A sufficient reply unambiguously picks one offered path: "preview it first" or "skip the preview and start the import" both work. When a reply approves without picking a path — "yes", "go ahead" — keep the gate open and ask which path in one short question. A reply that revises the plan and carries a direction — "tweak X and preview again", "tighten the filters and try again" — is itself sufficient: apply the revision and continue down that path in the same turn, showing the revised filter table with the result instead of stopping for fresh approval. Only a revision with no direction shows the revised table and asks the combined choice once. Preview, creation, and provider work wait for this combined approval. `list inspect` is read-only and can run before approval when the user names an existing List Workbook.

AI Ark people always follows its command's preview-first path. For that provider/entity, offer the preview as the only initial path; creation and run choices wait for the returned preview.

## Build

Compose the build command from the provider's guide — its example command, filters, and constraints are authoritative. `--name`, `--description`, `--limit`, `--preview`, `--run-request-id`, and `--run` are shared build flags for every provider. Creation requires a list name and a non-blank plain-language Workbook description; pass the approved values with `--name` and `--description`. Preview creates no Workbook and requires neither, so a filter-only preview can run before the name is settled; keep passing the approved `--name` once it is pinned so creation only drops `--preview` and adds the creation flags its provider guide requires. Never combine `--preview` with `--run`. Build commands also accept `--json`, `--org-id`, and `--token`; append `--org-id=<org-id>` after the complete subcommand path, and prefer `--json` for programmatic use.

For the full filter shape, write the `filters` object accepted by the provider's command to an absolute `.json` path and pass `--search-file <path>`. A search file and inline filter flags are alternative inputs; use exactly one style per the provider guide.

Creation is not idempotent. When the create command fails and prints that the request may have reached the server, confirm whether the named Workbook was created before you repeat the build command. When creation also uses `--run`, use a stable `--run-request-id` and keep it until the run outcome is certain.

## Approved preview or immediate creation

An immediate-action choice authorizes only the pinned create-only or create-and-run intent. For a preview choice, run the exact approved filters and requested `--limit` with `--preview`. Preview runs one provider search and creates no Workbook, Dataset, Dataset Source, or import run. Show every returned normalized entry in a compact Markdown table. For Apollo and AI Ark, show the returned `totalEntries` and `estimatedCreditCost`: `totalEntries` is the provider's full matching total independent of the requested limit and can exceed the 50,000-entry import cap; `estimatedCreditCost` is the customer-facing cost the command prints for the requested limit. Use both returned values directly; do not recalculate them.

Preview is an iteration loop, not a one-shot gate. When the user reacts to a preview by asking for tweaks or better matches — "let's get more of these to be churches" — they are still on the preview path: apply the tweaks and run the revised preview in the same turn, showing the revised filters alongside the new entries. Creation and import are the only actions that wait for an explicit go-ahead.

After showing a preview the user is happy with, ask for informed approval before full creation or import — again one natural question, offering to go ahead with the already-pinned run intent (create the list, or create it and start the import) or to stop here. Only after an unambiguous go-ahead, run the approved build command without `--preview`, adding `--run` and a stable `--run-request-id` when the pinned intent starts the import. A reply that stops ends the route without creating the list.

Without `--run-request-id`, each invocation generates a fresh ID, so pass an explicit stable ID to make retries and agent handoffs reproducible. After an uncertain run failure, retry with the exact command the CLI prints — it reuses the same ID.

## Run and inspect

Create without `--run` prints status `not_started`. Start an approved existing build with:

```bash
freckle list run <workbook-id> --request-id <stable-run-id>
```

Inspect progress with:

```bash
freckle list inspect <workbook-id>
```

Poll while status is `queued` or `running`. Stop on `completed` or `failed`. Report the returned `requestedEntries`, `importedEntries`, `currentPage`, `nextPage`, and public `failure` exactly as returned; do not infer intermediate progress or invent provider states.

AI Ark reports `currentPage` and `nextPage` as zero-based provider page indexes. Apollo reports them as one-based page indexes. In both cases, print the returned values without conversion.

For a completed list, page entries with `freckle workbook dataset entry list <workbook-id> <dataset-id> --limit 100` using the returned `datasetId`; when the output includes `nextCursor`, pass `--cursor "<nextCursor>"` for the next page and repeat until it is absent; the AI Ark guides name compact projection flags for their large stored payloads. The created asset handed to the user is the Workbook, linked with the org-scoped `url` field the CLI returned on it (`workbook inspect <workbook-id>` returns it again):

`[<list name>](<url from the Workbook object>)`

## From List to Workbook

A completed List is a normal Workbook whose Dataset holds the imported rows, so everything Freckle can do with a Workbook now applies to it. Deliver the Workbook link with the final import status, and in the same message offer the follow-ups that fit the imported entity — the route ends when the user has chosen a next step or declined one, not at the link. In plain language, offer:

- **People lists** — find verified work emails or mobile numbers, find LinkedIn profiles, validate emails, score the people, or send them to a connected tool such as HubSpot, Instantly, or HeyReach. For a new Apollo List that needs full last names, LinkedIn URLs, or emails at import time, choose the [Enriched List command](list/apollo-people.md#cost-line).
- **Company lists** — find people at the imported companies, enrich or score the companies, send them to a connected tool, or monitor them for new hires with [Dataset Signals](SIGNALS.md).

Present these as possibilities, not promises: which fields come back depends on the providers chosen in that follow-up.

A chosen follow-up treats the List Workbook as an existing target: follow [REFINE.md](REFINE.md) against it. The follow-up shape holds for every provider: inspect the chosen node contracts, author the Workflow, connect the List's Dataset as the connection input, and let the connection write results to its own separate output Dataset — the imported List Dataset is never modified. Every follow-up run goes through the sample gate ([WORKBOOKS.md#pending-and-triggering](WORKBOOKS.md#pending-and-triggering)).

**Completion** — every box checked:

- [ ] One unambiguous initial response approved the org, list name, provider, filters, requested limit, and run intent and selected either the recommended preview or the one immediate action matching that run intent.
- [ ] The pinned provider's guide was loaded before any build or preview command was composed.
- [ ] The approved filters — or their user-directed revisions — were sent with `--preview` only after the user chose the preview path; every returned compact preview entry, `totalEntries`, and `estimatedCreditCost` were shown for each preview.
- [ ] After a preview, an unambiguous go-ahead approved full creation or import; a stop ended the route without creation.
- [ ] Immediate creation followed only the combined gate's unambiguous run-intent choice; post-preview creation followed only the distinct informed approval.
- [ ] Every run used a stable request ID retained through any uncertain failure, and no uncertain create was repeated before checking for its Workbook.
- [ ] Every started import reached `completed` or `failed`, and only returned status, progress, and public failure fields were reported.
- [ ] Completed results were inspected from the returned Dataset, and the created Workbook link was delivered together with the entity's follow-up offers; a chosen follow-up routed through [REFINE.md](REFINE.md) (or [SIGNALS.md](SIGNALS.md) for monitoring).
- [ ] For Apollo people, the combined gate resolved the `basic` or `enriched` choice explicitly before creation, and an `enriched` choice used the direct `list build apollo people enriched` command.
