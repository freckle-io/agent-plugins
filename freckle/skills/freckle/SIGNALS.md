# Freckle Dataset Signals Reference

Dataset Signals watch the Dataset Entries a workspace already keeps in one input Dataset and append provider findings to a separate output Dataset in the same Workbook. The input Dataset is the desired monitor set: adding a Dataset Entry starts monitoring it, editing a Dataset Entry replaces its monitor, and deleting a Dataset Entry stops its monitor. Deleting the Signal Provider Configuration stops every monitor.

Provisioning, updates, and deletion are asynchronous. `signals get` prints the configuration status plus aggregate monitor counts (`total`, `provisioning`, `active`, `failed`, `deleting`, `paused`, and `deleted`); poll it until the expected terminal state. A successful create or delete command confirms that Freckle accepted the request, not that every monitor has reached its terminal state.

Signals use Freckle-managed provider access. Never ask for or pass a provider API key, webhook URL, or secret.

## Create

`signals list` prints the Signal types and their per-finding credit costs:

```bash
freckle signals list
freckle signals list --json
```

The CLI create command supports these Signal types:

**Filterable company**

- `company_job_openings` - Monitor job postings from company
- `company_new_hires` - Monitor new hires at company

**Contact**

- `contact_job_changes` - Monitor contact job changes

Both company types require `--company-domain-path`; `--company-profile-url-path` is optional. They also accept repeatable `--department`, repeatable `--seniority`, and repeatable `--job-titles`:

```bash
freckle signals create <input-dataset-id> <output-dataset-id> \
  --signal-type company_new_hires \
  --company-domain-path /company/domain \
  --company-profile-url-path /company/linkedinUrl \
  --department Operations \
  --seniority Director
```

### Company filter values

`--department` and `--seniority` accept only these exact values; anything else fails at create time. A finding must match one value from each provided filter, so combining them narrows results.

- Departments: `Accounting`, `Administrative`, `Business Development`, `Consulting`, `Customer Success`, `Design`, `Education`, `Engineering`, `Finance`, `Human Resources`, `Information Technology`, `Leadership`, `Legal`, `Manufacturing`, `Marketing`, `Media and Communication`, `Operations`, `Product Management`, `Project Management`, `Purchasing`, `Quality Assurance`, `Real Estate`, `Research`, `Sales`, `Support`
- Seniorities: `Owner`, `CXO`, `Vice President`, `Director`, `Manager`, `Senior`, `Entry`, `Training`, `Partner`

The CLI sends every filter you supply, and each one narrows the match. Repeat the flag to match any of several titles; each plain title is quoted automatically and the values combine with OR:

```bash
freckle signals create <input-dataset-id> <output-dataset-id> \
  --signal-type company_job_openings \
  --company-domain-path /company/domain \
  --job-titles "Senior Manager" \
  --job-titles "Head of Operations"
```

For full control, pass a single value containing quotes, parentheses, or `AND`/`OR`/`NOT`; it is sent as a raw boolean expression where multi-word titles must be double-quoted, e.g. `--job-titles '("Staff Engineer" OR "Principal Engineer") AND NOT "Manager"'`.

Contact job-change monitoring requires a company domain and a contact LinkedIn profile URL — job-change detection quality drops sharply without the profile URL. Contact email and full name pointers are optional supplements:

When you turn this signal on, Freckle runs an initial scan across your entire dataset to find anyone whose current job differs from your records, then keeps monitoring for changes going forward – each job change found is charged.

```bash
freckle signals create <input-dataset-id> <output-dataset-id> \
  --signal-type contact_job_changes \
  --company-domain-path /company/domain \
  --contact-profile-url-path /contact/linkedinUrl \
  --contact-email-path /contact/email
```

When the input Dataset lacks a LinkedIn profile URL column, add an enrichment step to the Workbook's Workflow that populates it, run that enrichment, and only then create the Signal. Entries whose profile URL is still blank at provisioning time fail as source-data exceptions instead of being monitored.

Before creating any Signal other than contact job changes, always ask the user exactly: **“Include results from last 24 hours?”**
Do not infer or default their answer, even if every other creation detail is known. If they answer yes, pass
`--include-last-24-hours`; if they answer no, omit it. The flag includes qualifying events from the 24 hours before each
monitor was created. If provider submission occurs more than 24 hours later, the cutoff is limited to the rolling 24
hours before submission. Without the flag, only events after provider creation qualify. Initial findings can arrive
asynchronously.

Contact job-change Signals do not support lookback. Do not ask the lookback question or pass
`--include-last-24-hours` when `--signal-type contact_job_changes` is selected.

Both Datasets must be active, distinct, and in the same active Workbook. Creation prints the Signal Provider Configuration id and a `signals get` command. It is asynchronous and may take up to 3 hours; Freckle emails the user when the Signal launches and when its first event arrives. When the organization is out of credits, creation fails with a billing URL; show the user that URL instead of retrying.

## Inspect configured Signals

List every active configuration in the current organization, configurations for one input Dataset, or configurations
across a Workbook:

```bash
freckle signals configuration list --active
freckle signals configuration list --input-dataset-id <input-dataset-id>
freckle signals configuration list --workbook-id <workbook-id>
freckle signals configuration list --workbook-id <workbook-id> --json
```

Exactly one scope flag is required. `--active` is organization-wide, returns only configurations whose status is
exactly `active`, and omits monitor status to keep the response compact. The Dataset and Workbook forms include monitor
status. The Workbook form aggregates configurations across its Datasets.

```bash
freckle signals get <signal-provider-configuration-id>
freckle signals get <signal-provider-configuration-id> --json
```

## Turn monitoring off or on

Toggle a Signal Provider Configuration by id. Turning it off preserves the configuration and historical findings:

```bash
freckle signals off <signal-provider-configuration-id>
freckle signals on <signal-provider-configuration-id>
```

`off` aliases `pause`; `on` aliases `reactivate`. The long forms and JSON output are also available:

```bash
freckle signals pause <signal-provider-configuration-id> --json
freckle signals reactivate <signal-provider-configuration-id> --json
```

Both operations are idempotent. A successful `off`/`pause` response reports `enabled: false`; a successful
`on`/`reactivate` response reports `enabled: true`. Their output prints only the configuration; monitors transition
asynchronously, so run `signals get` for monitor counts and progress:

```bash
freckle signals get <signal-provider-configuration-id>
```

Reactivation requires Signals to be enabled for the organization and enough available credits. Pause and reactivate do
not repair a non-zero `failed` count, and the CLI has no retry command; direct the user to the web app.

## Delete

```bash
freckle signals delete <signal-provider-configuration-id>
freckle signals delete <signal-provider-configuration-id> --json
```

Delete is idempotent and asynchronous. Repeating it is safe. Historical findings remain in the output Dataset. While deletion is in progress, new findings can still be stored, billed, and admitted to downstream connections. Poll `signals get` until the configuration is `deleted`.
