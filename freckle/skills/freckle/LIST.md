# List Building

A List is a Workbook whose Dataset is filled by an import from a provider search. The `list` commands manage the whole import, including search paging, checkpoints, and resume; do not assemble a Workflow or Dataset connection for the import itself — follow-ups come afterwards through [From List to Workbook](#from-list-to-workbook).

## Providers

Every provider follows the same lifecycle below. Once the provider and entity are pinned, read the selected build command's `--help` before composing any build or preview command. Help owns syntax, examples, defaults, constraints, and output shapes. Load a provider reference from the table only for advanced JSON filters or an Apollo people search inside a Workflow.

| Provider | Entity | Build command | Stands out for | Each imported row holds | Cost shape | Reference |
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

Show those choices in a compact filter table that includes the selected provider's cost shape below. Ask for plan approval and the preview-or-create choice in one response, phrased as one natural question a colleague would ask — the two paths woven into the sentence, the recommendation stated in passing, and an open invitation to tweak the plan. The question offers two paths:

- **preview first (recommended)** — approve this exact plan and preview up to 10 matching entries before committing to the full import; and
- the one immediate action matching the pinned run intent — create the list now when the pinned run intent is create-only, or create it and start the import when the pinned run intent includes starting the import.

For example: "Want me to pull a quick preview of up to 10 matches first — that's what I'd do — or create the list and import all 1,000 right away? If anything in the plan needs a tweak, just say the word." A sufficient reply unambiguously picks one offered path: "preview it first" or "skip the preview and start the import" both work. When a reply approves without picking a path — "yes", "go ahead" — keep the gate open and ask which path in one short question. A reply that revises the plan and carries a direction — "tweak X and preview again", "tighten the filters and try again" — is itself sufficient: apply the revision and continue down that path in the same turn, showing the revised filter table with the result instead of stopping for fresh approval. Only a revision with no direction shows the revised table and asks the combined choice once. Preview, creation, and provider work wait for this combined approval. `list inspect` is read-only and can run before approval when the user names an existing List Workbook.

AI Ark people always follows its command's preview-first path. For that provider/entity, offer the preview as the only initial path; creation and run choices wait for the returned preview. This List contains the base People Search payload only: Email Finder and mobile finder are separate future enrichments and stay out of this command.

## Cost disclosure

For Apollo and AI Ark companies, explain one page charge per committed non-empty provider page of up to 100 companies; pages returning no companies cost nothing. An explicit limit costs at most `ceil(requested limit ÷ 100)` page charges; with no limit, the preview estimates `ceil(min(totalEntries, 50,000) ÷ 100)` page charges. AI Ark people bills per returned person. Quote the `estimatedCreditCost` the preview command prints rather than pricing the page charge or person yourself; do not substitute provider-side pricing.

## Apollo people mode

Use Apollo People Search directly; do not search for companies first.

The people cost line is a mode choice; show both modes with the plan table and weave the mode question into the combined gate's one natural question. A sufficient combined-gate reply picks both a mode and a path; when either is missing, keep the gate open and ask for the missing piece:

- `basic` — use `freckle list build apollo people`. Results show first name, an obfuscated last name such as `J********`, job title, and company name. This import costs 0 credits and records no Freckle credit usage.
- `enriched` — use `freckle list build apollo people enriched`. The import searches and then bulk-enriches the candidates, stores only people Apollo successfully enriches, and bills the credit price the command prints once per stored enriched person. A candidate Apollo cannot enrich is neither stored nor billed. Fields such as full last name, LinkedIn URL, email address, and company domain are returned only when Apollo has them — present them as possible outcomes, never promised columns.

The enriched command is a direct List import, not a Workflow follow-up: do not create a Basic List first and do not try to enrich imported Apollo IDs one at a time. Its `--limit` caps search candidates, so failed enrichments can make the final `importedEntries` lower than the requested limit.

Apollo's preview returns up to 10 normalized search-only people showing name with an obfuscated last name, title, and organization. Preview costs 0 credits in either mode. For Enriched, report the returned `estimatedCreditCost` as the maximum for the requested candidate limit; actual usage follows the enriched people the import returns and can be lower.

## Build

Compose the command from the selected command's `--help`, passing the approved filters and creation metadata. A preview can run before the name is settled; keep passing the approved name once pinned. Prefer `--json` for programmatic use. For filters beyond the inline flags, load the selected provider reference and preserve the approved JSON object exactly.

- Creation is not idempotent. After an uncertain create failure, check for the Workbook before repeating the build.
- Choose a stable `--run-request-id` for each import and retain it across retries and agent handoffs. Follow the CLI's retry command, retaining the resolved `--org-id`, any authentication overrides, and `--json` when used originally.

## Approved preview or immediate creation

An immediate-action choice authorizes only the pinned create-only or create-and-run intent. For a preview choice, run the exact approved filters and requested `--limit` with `--preview`.

- Show every returned normalized entry in a compact Markdown table.
- For Apollo and AI Ark, show the returned `totalEntries` and `estimatedCreditCost`. Use both returned values directly; do not recalculate them.
- `totalEntries` is the provider's full matching total, independent of the requested limit, and can exceed the 50,000-entry import cap.
- For AI Ark people, also show the requested import count as `requestedEntries`.
- Use `--raw` only when the complete provider preview records are explicitly needed.

Preview is an iteration loop, not a one-shot gate. When the user reacts to a preview by asking for tweaks or better matches — "let's get more of these to be churches" — they are still on the preview path: apply the tweaks and run the revised preview in the same turn, showing the revised filters alongside the new entries. Creation and import are the only actions that wait for an explicit go-ahead.

After showing a preview the user is happy with, ask for informed approval before full creation or import — again one natural question, offering to go ahead with the already-pinned run intent (create the list, or create it and start the import) or to stop here. Only after an unambiguous go-ahead, run the approved build command without `--preview`, adding `--run` and a stable `--run-request-id` when the pinned intent starts the import. A reply that stops ends the route without creating the list. For AI Ark people, add `--yes` after this approval; `--yes` bypasses the CLI prompt, not the user approval gate.

## Run and inspect

Before starting an approved existing List, read `freckle list run --help` and compose the command from that help, using a stable request ID.

Before checking progress, read `freckle list inspect --help`. Poll while status is `queued` or `running`. Stop on `completed` or `failed`. Report returned status, progress, and public failure fields exactly as returned; do not infer intermediate progress or invent provider states.

For completed results, read `freckle workbook dataset entry list --help`. Use the returned `datasetId`, prefer the matching compact projection for AI Ark results, and follow pagination until all requested results have been retrieved. Use the full stored payload only when explicitly needed.

The created asset handed to the user is the Workbook, linked with the org-scoped `url` field the CLI returned on it (`workbook inspect <workbook-id>` returns it again):

`[<list name>](<url from the Workbook object>)`

## From List to Workbook

A completed List is a normal Workbook whose Dataset holds the imported rows, so everything Freckle can do with a Workbook now applies to it. Deliver the Workbook link with the final import status, and in the same message offer the follow-ups that fit the imported entity — the route ends when the user has chosen a next step or declined one, not at the link. In plain language, offer:

- **People lists** — find verified work emails or mobile numbers, find LinkedIn profiles, validate emails, score the people, or send them to a connected tool such as HubSpot, Instantly, HeyReach, or Lemlist. For a new Apollo List that needs full last names, LinkedIn URLs, or emails at import time, choose the [Enriched List command](#apollo-people-mode).
- **Company lists** — find people at the imported companies, enrich or score the companies, send them to a connected tool, or monitor them for new hires with [Dataset Signals](SIGNALS.md).

Present these as possibilities, not promises: which fields come back depends on the providers chosen in that follow-up.

A chosen follow-up treats the List Workbook as an existing target: follow [REFINE.md](REFINE.md) against it. The follow-up shape holds for every provider: inspect the chosen node contracts, author the Workflow, connect the List's Dataset as the connection input, and let the connection write results to its own separate output Dataset — the imported List Dataset is never modified. Every follow-up run goes through the sample gate ([WORKBOOKS.md#pending-and-triggering](WORKBOOKS.md#pending-and-triggering)).

**Completion** — every box checked:

- [ ] One unambiguous initial response approved the org, list name, provider, filters, requested limit, and run intent and selected either the recommended preview or the one immediate action matching that run intent.
- [ ] The selected build command's `--help` was read before composing a build or preview, and run, inspect, and entry-list help was read when entering those steps; provider references were loaded only for advanced filters or Workflow routing.
- [ ] The approved filters — or their user-directed revisions — were sent with `--preview` only after the user chose the preview path; every returned compact preview entry, `totalEntries`, and `estimatedCreditCost` were shown for each preview.
- [ ] After a preview, an unambiguous go-ahead approved full creation or import; a stop ended the route without creation.
- [ ] Immediate creation followed only the combined gate's unambiguous run-intent choice; post-preview creation followed only the distinct informed approval.
- [ ] Every run used a stable request ID retained through any uncertain failure, and no uncertain create was repeated before checking for its Workbook.
- [ ] Every started import reached `completed` or `failed`, and only returned status, progress, and public failure fields were reported.
- [ ] Completed results were inspected from the returned Dataset, and the created Workbook link was delivered together with the entity's follow-up offers; a chosen follow-up routed through [REFINE.md](REFINE.md) (or [SIGNALS.md](SIGNALS.md) for monitoring).
- [ ] For Apollo people, the combined gate resolved the `basic` or `enriched` choice explicitly before creation, and an `enriched` choice used the direct `list build apollo people enriched` command.
