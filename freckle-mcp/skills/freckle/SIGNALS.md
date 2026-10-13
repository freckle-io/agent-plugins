# Dataset Signals

Signals watch the input Dataset's desired monitor set and append findings to a distinct output Dataset in the same active Workbook. Add/edit/delete input entries starts/replaces/stops their monitors. Configuration deletion stops all monitors. Provisioning and deletion are asynchronous; acceptance does not mean every monitor is ready.

Use `signals_listSignalTypes` for supported types and per-finding prices. Current types include company_job_openings, company_new_hires, and contact_job_changes. Inspect `signals_createSignalProviderConfiguration`'s union schema for exact mappings/filter names. Company signals need a domain pointer and optionally profile URL; department/seniority/title filters narrow matches. Preserve Boolean title expressions explicitly; do not send repeated shell flags. Use only returned/schema-supported enum values.

Contact job changes need company domain and contact LinkedIn profile URL; email/full name are supplementary. Enrich missing LinkedIn profiles first. Blank profiles fail as source-data exceptions. Initial scan compares current jobs with stored records and charges each discovered change; this type has no lookback option.

## One round, then create

Lead one batched decision round with what will be watched, what qualifies, where findings land and cost per finding. Settle input/output Dataset and filters. For non-contact-job-change Signals, ask **“Include results from last 24 hours?”** without a recommendation unless the user already explicitly decided it. Map yes/no to the schema's lookback field. The user's answers authorize creation in the same turn; no second plan gate. Initial findings may arrive asynchronously.

Both Datasets must be active, distinct, and in the same active Workbook. Signals use managed provider access: never request provider keys, webhook URLs or secrets. Out-of-credits errors can include a billing URL; return it instead of retrying.

## Inspect and operate

- `signals_listActiveSignalProviderConfigurations` lists exactly-active configurations in the org without detailed monitor status.
- `signals_listSignalProviderConfigurations` lists one input Dataset. For a Workbook inspect its Datasets and/or `signals_listSignalProviderConfigurationMonitorStatuses`.
- `signals_getSignalProviderConfiguration` reports configuration and monitor counts: provisioning, active, failed, deleting, paused, deleted. Poll for the requested state; launch can take hours, so report pending honestly and use the product's notifications rather than claiming readiness.
- `signals_pauseSignalProviderConfiguration` and `_reactivateSignalProviderConfiguration` preserve historical findings. Reactivation needs feature access and credits; neither repairs failed monitors. There is no retry tool; direct the user to the app for those failures.
- `signals_deleteSignalProviderConfiguration` is idempotent and asynchronous. During deletion, findings can still be stored/billed and admitted downstream. Poll until deleted; old findings remain.
