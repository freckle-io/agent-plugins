---
name: freckle
description: Use when the user asks Freckle to build lists, enrich or score leads, import CRM data, author or run workflows, monitor Dataset Signals, sync Ads audiences, inspect credits, or manage Freckle workspace connections through MCP.
---

# Freckle through MCP

Use the Freckle MCP tools connected by this plugin. Tool names below are server names; the host may prepend its server namespace. Read the relevant route before acting. Tool JSON Schemas are authoritative for arguments and returned fields. HTTP tools take `params` (resource IDs), `query` (filters, dates, cursors; `{}` when empty), and/or `payload` (JSON body), and return structured `data`. The two workspace helpers return direct objects.

| User wants | Read |
| --- | --- |
| Build a provider-backed company or people list | [LIST.md](LIST.md) |
| New enrichment, scoring, research, or processing job | [BUILD.md](BUILD.md) |
| Change or run an existing Workbook/Workflow identified by URL, ID or name | [REFINE.md](REFINE.md) |
| Import CSV/rows, manage Datasets, webhook, mappings or connection runs | [WORKBOOKS.md](WORKBOOKS.md); new import-only jobs use BUILD's fast lane |
| Import/refresh/schedule HubSpot or Salesforce data | [CRM.md](CRM.md) |
| Inspect nodes, validate drafts, publish or directly invoke saved Workflows | [workflow/mcp-reference.md](workflow/mcp-reference.md) |
| Monitor changes | [SIGNALS.md](SIGNALS.md) |
| Push a Dataset to LinkedIn, Meta or Google Ads | [ADS.md](ADS.md) |
| Balance, spend, pricing or sample costs | [CREDITS.md](CREDITS.md) |
| Workspace identity or authorization | [SETUP.md](SETUP.md) |
| Provider connections, BYOK or HTTP credentials | [CONNECTIONS.md](CONNECTIONS.md) |

## Shared operating rules

- Preserve the user's intent and prior authorization. For new builds, pin the goal, inspect contracts, present the plan, then implement the approved shape. Existing-target work follows REFINE's fit test. Import-only work does not authorize enrichment or external delivery.
- When decisions remain, use a batch grill: ask all currently unblocked shape-changing questions together, numbered, with recommendations. Recompute after replies; dependent decisions wait. Facts available through tools are agent work. Pick short descriptive names unless the user supplies names.
- Lead plans and decision rounds with two or three plain sentences describing which rows run, what happens to each, where results land and what it costs. Speak to a GTM audience; technical tables support the explanation.
- Call `workspace_context` first. Its org is fixed by OAuth consent. Resolve a named resource inside that org using IDs/URLs and paged list/get tools. If its org differs, have the user reauthorize the MCP connection for that Workspace; do not silently use another org or claim cross-org search. A Workspace already supplied by the user or established in this chat needs no repeat confirmation.
- Read the selected tool schema before constructing arguments. Supply JSON values directly, not shell flags or local file paths. Preserve nested filter groups and stable request IDs. Never install or invoke a Freckle executable.
- Never retry an ambiguous create/start blindly. Inspect known IDs and state first. Admission is not completion; poll status/results until terminal or report honestly that work remains pending.
- Use cursor pages and compact projections for tables. Preserve IDs, source keys, exact credit strings and returned resource URLs. Read a client-supplied CSV using available file tools, then send parsed rows in small batches; the server cannot open client files.
- For more than 20 rows, follow the ten-row sample gate in WORKBOOKS before expanding. Report actual terminal sample costs and forecast separately. Never describe an unexecuted plan or admitted run as a completed result.
- Secrets belong in the authenticated browser connection form, never chat or tool arguments. Select only returned authorized credentials. Sales reps must use the separately configured Rep MCP; this plugin requires a Builder or Admin role.
