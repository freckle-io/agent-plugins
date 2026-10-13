# Ads audience syncs

A sync sends one Dataset to an audience in one connected LinkedIn, Meta or Google ad account every 24 or 48 hours. Creating a sync creates the audience. Pushing costs no Freckle credits and does not find emails; enrich first and use the output Dataset if necessary.

Choose from `integrationCredentials_list` only credentials with `status: authorized` and an adAccount. Show account names. If none qualifies, use `connections_setup` with linkedin_ads, meta_ads or google_ads and have the user select the ad account in the browser.

Inspect the Dataset catalog. Map usable email/hash/provider-hash output and all relevant supported fields using the exact `adAudienceSyncs_createAdAudienceSync` schema. Meta accepts first/last/country/phone/city/state; LinkedIn first/last/country/company/title; Google email. Company means company name, never address. Unsupported or overlong values may be omitted; never promise a match.

One batched decision round settles connection, audience name, 24/48-hour cadence and ambiguous field mappings. Lead with the Dataset/count, destination account/audience, cadence, and free push cost. The answers authorize creation. Confirm returned credential, audience and schedule. First push begins shortly after creation; do not claim it completed.

Use `adAudienceSyncs_listAdAudienceSyncs` for stored status and `_getAdAudienceSync` for bounded platform refresh. Distinguish lastRun (succeeded/failed/skipped, reason, contacts, sent hashes, unusable emails) from platformStats (processing/ready/failed and platform match metrics). A note can mean only stored status is available.

Meta/Google add people; Dataset deletions do not remove them. LinkedIn replaces its entire list and can skip while a previous upload is still processing. LinkedIn matchedCount/inputCount counts hashes; Meta approximate counts count people relative to contactCount; Google reports platform-specific sizes/match rate. Report the right denominator.

`adAudienceSyncs_updateAdAudienceSync` changes enabled/cadence/mappings as permitted by its schema; `_runAdAudienceSync` requests a push and rejects off/running/stopped syncs. `_deleteAdAudienceSync` stops sync but leaves the audience in the platform. Relay failure reasons: reconnect, select ad account, grant Google Data Manager access, or accept platform terms. A deleted credential permanently stops that sync; replacement requires a new sync.
