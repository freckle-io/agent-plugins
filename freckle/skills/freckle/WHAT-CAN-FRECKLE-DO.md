# What Can Freckle Do

Use this template to describe Freckle and its current CLI capabilities.

```text
- Build Workbooks: load your rows into a dataset (CSV, pasted records, a webhook feed, or a manual or scheduled HubSpot or Salesforce record import including list or custom SOQL selection), wire a workflow to them, and collect the newest result per row in an output dataset.
- Build net-new company or people lists from Apollo or AI Ark provider searches: pin filters, preview a sample, then import matching entries straight into a Workbook dataset — and continue from the finished list into enrichment, scoring, monitoring, or CRM follow-ups on that Workbook. Apollo List building offers a free Basic people search and a paid Enriched people command; AI Ark people import rich base profiles and nested company data without Email Finder or mobile finder.
- Run data through workflows: trigger a workbook connection on demand or automatically as rows arrive, sample-run before full volume, and re-run rows that failed on their current values.
- Author lead-enrichment workflows: inspect provider nodes, write typed workflow_draft YAML, validate it through the compiler, and save or publish it.
- Find people inside a workflow run with Freckle-provided Apollo access and hand basic or enriched person records into a dedicated Dataset by default, or an existing Dataset the user selects.
- Push object collections into same-Workbook Datasets during a workflow run, then chain other workflows from those entries.
- Reuse what exists: list Workbooks with their wiring, list saved workflows with their input/output shapes, export editable drafts, publish new revisions, and update workflow metadata.
- Run workflows on sample inputs: invoke a saved workflow with JSON object inputs and inspect asynchronous run results.
- Manage Workbook datasets: list and create datasets, import CSV or selected HubSpot or Salesforce records, inspect, rerun, or schedule those imports, manage entries and webhooks, and connect datasets to saved workflows.
- Monitor Dataset Entries for company job openings, company new hires, or contact job changes, route findings into an output Dataset, inspect asynchronous lifecycle progress, and request safe remote cleanup.
- Connect integrations: open Freckle's web app to connect Apify, ContactOut, HeyReach, HubSpot, Instantly, Lemlist, OpenAI, Salesforce, Slack, or Supabase credentials, list connection status, and inspect public credential IDs.
- Call any HTTP API with your own API key: save the key once in Freckle's web app, and workflows reference it by its saved credential ID — the key itself never appears in chat or workflow files.
- Report credits: show the current Workspace balance and exact usage by Workbook, Workflow within a Workbook, or billed enrichment node for an inclusive date range.
- Manage CLI setup: authenticate, list available organizations, work in the org the user chooses, and inspect active API/app endpoints.
```

Apollo list cost guidance and the basic-versus-enriched people decision live in [List building](LIST.md#apollo-people-mode); quote the returned API cost estimates.

End by asking whether the user wants to build a workbook for their data, build a company or people list, author a workflow, inspect existing workflows or workbooks, connect an integration, check credits, or run a saved workflow with sample inputs.
