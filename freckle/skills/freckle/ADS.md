# Freckle Ad Audience Syncs Reference

An Ad Audience Sync pushes the Dataset Entries of one Dataset to one audience in a LinkedIn Ads, Meta Ads, or Google Ads ad account, every 24 or 48 hours. Freckle creates the audience in the connection's ad account when the sync is created. Each run pushes every entry with a usable email:

- Meta and Google only add people. Deleting a Dataset Entry does not remove anyone from the audience.
- LinkedIn replaces its whole list each run, once LinkedIn has finished building the previous upload. A run that finds LinkedIn still building is skipped, and the next scheduled run tries again.

Pushing costs no Freckle credits. A sync does not find emails: when the Dataset lacks them, add a Workflow that finds them (for example a hashed email waterfall), run it, and point the sync at its output Dataset.

## Pick the connection and fields

Each ads connection targets exactly one ad account. List the user's connections for the platform:

```bash
freckle connections show meta_ads --json --org-id=<org-id>
```

Offer only connections whose `status` is exactly `authorized` and that have an `adAccount`, and show each one's ad account name. If none qualifies, follow [CONNECTIONS.md](CONNECTIONS.md): open the connection page and ask the user to connect and choose the ad account there.

Pick fields from the Dataset's field catalog as JSON Pointers. The email is required; it may be a plain email, a SHA-256 hash, or a hashed email provider result. Map every other field the Dataset has that the platform accepts:

| Field flag | Meta | LinkedIn | Google |
| --- | --- | --- | --- |
| `--first-name-path`, `--last-name-path`, `--country-path` | yes | yes | no |
| `--phone-path`, `--city-path`, `--state-path` | yes | no | no |
| `--company-path`, `--title-path` | no | yes | no |

Map `--company-path` to the company name, never its address. LinkedIn takes at most 35 characters for a first or last name and 50 for a company or job title, so a longer value is left out of that contact's row. `--country-path` can point at country names or two-letter codes; a value that is neither is left out.

## One round, then create

A sync gets exactly one [batch grill](SKILL.md#shared-operating-rules) round before `ads create`. Lead with the [what-will-run summary](SKILL.md#shared-operating-rules), for example: "Every day Freckle pushes the 1,240 people in *Hashed contacts* to a new Meta Ads audience, *Q4 ICP*, in the Acme ad account. Pushing is free." Then number each unsettled decision with a recommendation:

- Which connection, when more than one qualifies.
- The audience name (recommend one from the user's goal).
- Every 24 or 48 hours (recommend 24).
- Which Dataset fields to map, when it is not obvious.

The user's answers are the approval; create in the same turn:

```bash
freckle ads create <dataset-id> --credential-id <credential-id> --audience-name "Q4 ICP" --email-path /email --first-name-path /firstName --last-name-path /lastName --org-id=<org-id>
freckle ads create <dataset-id> --credential-id <credential-id> --audience-name "Q4 ICP" --email-path /hashedEmails --company-path /company --title-path /title --every 48h --org-id=<org-id>
```

The Dataset must be active, in an active Workbook. The first push starts about a minute after creation.

- [ ] The user's answers to the one batch grill round settled every numbered decision.
- [ ] `ads create` exited 0, and its `sync` shows the chosen connection's `credentialId`, the audience name, and the schedule the user approved.

## Inspect

```bash
freckle ads list --dataset-id <dataset-id> --org-id=<org-id>
freckle ads list --workbook-id <workbook-id> --org-id=<org-id>
freckle ads get <sync-id> --org-id=<org-id>
```

- `lastRun` is what Freckle's last push did: `succeeded`, `failed`, or `skipped`, with a `reason` to relay to the user, plus how many hashed emails were sent, from how many contacts (`contactCount`), and how many entries had no usable email. A `succeeded` run can have a `reason` too: it names the values the platform does not accept, which were left out. A company left out for most contacts usually means an address is mapped as the company; offer to map the company name instead.
- `platformStats` is what the platform last reported: `processing`, `ready`, or `failed`, with the last match numbers it reported. LinkedIn's match rate is `matchedCount` ÷ `inputCount` (both count hashed emails) and `audienceSize` is the members it can target. Meta's `approximateCount` bounds are matched people, so read them against `lastRun.contactCount`. Google's numbers come from the list itself: `matchRatePercentage` and its sizes on Search, Display, YouTube, and Gmail (`searchNetworkMembersCount`, `displayNetworkMembersCount`, `youtubeMembersCount`, `gmailMembersCount`). `ads get` asks the platform for the latest status at most once a minute while an upload is processing, and at most once an hour once it is ready, so it is fine to run it again to follow progress. `ads list` shows stored status only.
- A `note` means the platform could not be reached just now and the stored status is shown.

## Turn off or on, change the schedule, run now

```bash
freckle ads off <sync-id> --org-id=<org-id>
freckle ads on <sync-id> --org-id=<org-id>
freckle ads update <sync-id> --every 48h --org-id=<org-id>
freckle ads run <sync-id> --org-id=<org-id>
```

`run` pushes within a few seconds, exactly as a scheduled run would; it refuses a sync that is off, already running, or stopped (for example by a deleted connection), and says why.

## Delete

```bash
freckle ads delete <sync-id> --org-id=<org-id>
```

Deleting stops the sync. The audience stays in the ad platform.

## When a run fails

Relay the `lastRun.reason`. The common ones:

- Reconnect the platform, or choose the connection's ad account, in Settings → Integrations.
- Google needs Data Manager access granted when connecting.
- The platform refused the upload, for example because Meta's Custom Audience terms are not accepted. The user fixes it in the ad platform; the next run retries.
- A deleted connection stops the sync for good: delete it and create a new one with another connection.
