# Freckle Dataset Signals Reference

Dataset Signals watch the Dataset Entries a workspace already keeps in one input Dataset and append provider findings to a separate output Dataset in the same Workbook. The input Dataset is the desired monitor set: adding a Dataset Entry requests a monitor, editing a Dataset Entry safely deactivates and replaces its remote monitor, and deleting a Dataset Entry requests remote cleanup. Deleting the Signal Provider Configuration requests cleanup for every monitor.

Provisioning and deletion are asynchronous. Commands report the configuration status plus aggregate monitor counts (`provisioning`, `active`, `failed`, `deleting`, and `deleted`); use `signals get` to follow progress. A successful create or delete command confirms that Freckle accepted the request, not that every remote monitor has already reached its terminal state.

Signals use Freckle-managed provider credentials and polling. Never ask for or pass a provider API key, webhook URL or secret, event key path, bulk id, or remote radar id.

## Create

Use the backend catalog to see Signal types and their per-finding credit costs:

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

- Departments: `Accounting`, `Administrative`, `Business Development`, `Consulting`, `Customer Success`, `Design`, `Education`, `Engineering`, `Finance`, `Human Resources`, `Information Technology`, `Legal`, `Manufacturing`, `Marketing`, `Media and Communication`, `Operations`, `Product Management`, `Project Management`, `Purchasing`, `Quality Assurance`, `Real Estate`, `Research`, `Sales`, `Support`
- Seniorities: `Owner`, `CXO`, `Vice President`, `Director`, `Manager`, `Senior`, `Entry`, `Training`, `Partner`

`--job-titles` overrides `--department` and `--seniority` when present, so pick one style of filtering per Signal. Repeat the flag to match any of several titles; each plain title is quoted automatically and the values combine with OR:

```bash
freckle signals create <input-dataset-id> <output-dataset-id> \
  --signal-type company_job_openings \
  --company-domain-path /company/domain \
  --job-titles "Senior Manager" \
  --job-titles "Head of Operations"
```

For full control, pass a single value containing quotes, parentheses, or `AND`/`OR`/`NOT`; it is sent as a raw boolean expression where multi-word titles must be double-quoted, e.g. `--job-titles '("Staff Engineer" OR "Principal Engineer") AND NOT "Manager"'`.

Contact job-change monitoring also requires a company domain and at least one contact identifier. Supply any combination of contact email, profile URL, and full name pointers:

```bash
freckle signals create <input-dataset-id> <output-dataset-id> \
  --signal-type contact_job_changes \
  --company-domain-path /company/domain \
  --contact-email-path /contact/email \
  --contact-profile-url-path /contact/linkedinUrl
```

Before creating any Signal, always ask the user exactly: **“Include results from last 24 hours?”** Do not infer or
default their answer, even if every other creation detail is known. If they answer yes, pass `--include-last-24-hours`;
if they answer no, omit it. The flag includes qualifying events from the 24 hours before each monitor was created. If
provider submission occurs more than 24 hours later, the cutoff is limited to the rolling 24 hours before submission.
Without the flag, only events after provider creation qualify. Initial findings can arrive asynchronously.

Both Datasets must be active, distinct, and in the same Workbook. Creation prints the Signal Provider Configuration id and a `signals get` command. It is asynchronous and may take up to 3 hours; Freckle emails the user when the Signal launches and when its first event arrives.

## Inspect configured Signals

List every active configuration in the current organization, configurations for one input Dataset, or configurations
across a Workbook:

```bash
freckle signals configuration list --active
freckle signals configuration list --input-dataset-id <input-dataset-id>
freckle signals configuration list --workbook-id <workbook-id>
freckle signals configuration list --workbook-id <workbook-id> --json
```

Exactly one scope flag is required. `--active` is organization-wide, excludes paused or deleting configurations, and
omits monitor status to keep the response compact. The Dataset and Workbook forms include monitor status. The Workbook
form aggregates configurations across its Datasets.

```bash
freckle signals get <signal-provider-configuration-id>
freckle signals get <signal-provider-configuration-id> --json
```

Output contains only product configuration and safe lifecycle data. It never contains managed credentials, remote radar ids, bulk correlation, leases, or raw provider errors.

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
`on`/`reactivate` response reports `enabled: true`. Remote monitors transition asynchronously, so inspect progress after
either operation:

```bash
freckle signals get <signal-provider-configuration-id>
```

Reactivation requires Signals to be enabled for the organization and enough available credits.

## Delete

```bash
freckle signals delete <signal-provider-configuration-id>
freckle signals delete <signal-provider-configuration-id> --json
```

Delete is idempotent and asynchronous. Repeating it is safe. Historical findings remain in the output Dataset while remote monitors drain; late polled findings are ignored and do not create new Dataset Entries or Workflow admissions. Poll `signals get` until the configuration is `deleted`.
