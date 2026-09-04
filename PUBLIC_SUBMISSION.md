# Freckle public plugin submission

Status: preparation only. No public submission has been made. This repository
currently distributes a CLI-backed plugin; it does not contain a hosted MCP server.

## Architecture gate

OpenAI's [migration guide](https://developers.openai.com/plugins/guides/submit-claude-plugin)
directs plugins requiring persistent credentials to the **With MCP** submission
path and asks developers to contact an OpenAI partner when core behavior needs
local execution. Freckle's current CLI downloads a native executable and persists
authentication locally. We have neither an MCP endpoint nor a known partner
contact, so do not submit this archive as a confirmed skills-only solution.

Recommended next implementation: a hosted Freckle MCP integration with OAuth,
plus skills adapted to its tools. Keep the current CLI package for coding-agent
users. A GitHub marketplace entry alone does not create a public listing.

## Listing copy

- Name: Freckle
- Publisher: Freckle (business identity must be verified by the publisher)
- Proposed category: Productivity; confirm against portal choices
- Short description: Build prospect lists, enrich leads, and score companies with Freckle.
- Logo: `freckle/assets/freckle.png` (existing 640 × 640 Freckle artwork)
- Website: https://freckle.io
- Privacy: https://freckle.io/privacy-policy
- Terms: https://freckle.io/terms-of-service
- Support URL: publisher must supply the official public support destination

Proposed long description for the future MCP version (use only after those
workflows are implemented and tested):

> Build company and people lists, enrich lead data, and score companies against
> your ideal customer profile with Freckle. Create Workbooks and reusable
> Workflows, review sample results and credit estimates, and approve a full run
> when you are ready. Inspect credit usage and revisit existing Workbooks in
> conversation. Requires a Freckle account and credits for paid operations.

Starter prompts:

1. Use Freckle to build a list of 50 fintech companies that match my ideal customer profile.
2. Use Freckle to enrich this company-domain CSV and show a sample and credit forecast before the full run.
3. Use Freckle to summarize my credit usage by Workbook.

The repository manifest describes the current CLI version honestly. Replace its
local-runtime requirements only when the public MCP version exists.

## Proposed first MCP scope

Implement in the Freckle backend, reusing existing service authorization and
business logic. This is a design proposal, not an assertion that these tools exist.

| Capability | Proposed behavior |
| --- | --- |
| Account and organizations | Identify the connected account and return only organizations it may access. Bind every operation to an authorized organization. |
| Credits and catalog | Return balances, usage, supported node contracts, and cost information for planning. |
| Workbook inspection | List and read existing Workbooks, datasets, and saved Workflow definitions. |
| Workbook preparation | Create a draft from the agreed inputs, output fields, and scoring criteria. Return a reviewable identifier and URL. |
| Sample execution | Run only the agreed sample, return a run ID, poll status, and expose results and actual credit usage. |
| Full execution | Execute the approved scope after sample review and a credit forecast; prevent accidental duplicate paid runs. |

Use explicit structured tools rather than a shell-command passthrough. Validate
resource ownership on the server, reject cross-organization access, protect
secrets in logs and responses, and apply bounded pagination. Label read/write and
destructive behavior accurately. Choose the smallest tool set that supports the
five positive tests below; defer connection management and Dataset Signals if
they expand the first review unnecessarily.

OAuth needs to connect the user to the same Freckle authorization model as the
product. The public workflow must not require a CLI token in chat, a PATH change,
or permission hooks. Adapt the skills at their upstream source: the release
pipeline owns `freckle/skills/freckle/`, so direct edits here would be overwritten.

Before adapting setup, reconcile the current instruction mismatch: the generated
`freckle/skills/freckle/SETUP.md` says to read the structured auth status and warns
that exit zero alone does not prove authentication; `freckle/skills/setup/SKILL.md`
currently uses an exit-code-oriented check. The public OAuth flow needs its own
verified connection check.

## Reviewer fixtures and test cases

These are proposed acceptance tests, **not executed results**. Provision a
dedicated review account with synthetic business records and a bounded credit
allowance. Supply its credentials only through the portal's private review fields.
Populate a Workbook named `Plugin Review`, a saved company-enrichment Workflow,
and known usage totals. Record their actual identifiers in private reviewer notes.

The CSV fixture for the sample test should contain 20 public company domains,
one per row under a `domain` header, chosen and validated by the Freckle team.
Use real provider-backed domains for enrichment; use synthetic data for internal
record-access tests. Reset mutable fixtures before each repeated test.

| ID | Prompt or scenario | Fixture | Expected behavior and result |
| --- | --- | --- | --- |
| P1 | “Use Freckle to show my Workbooks.” | Review account with `Plugin Review` | Authenticate, resolve organization access, and list authorized Workbooks with names and links. No paid run or mutation. |
| P2 | “How many Freckle credits have I used by Workbook?” | Seeded usage totals | Read credits and usage, report totals and attribution limits matching the fixture. Do not create or run Workflows. |
| P3 | “Inspect Plugin Review and explain its inputs and outputs.” | Seeded Workbook and saved Workflow | Read the named resource, derive its organization, and explain the existing configuration without modifying it. |
| P4 | “Enrich these 20 domains with company size and industry. Show me 10 sample rows and the forecast before running the rest.” | Approved CSV and bounded credits | Confirm the design, prepare the Workbook, execute only the agreed 10-row sample, and report results, actual sample credits, forecast, and resource links. Wait for approval before remaining rows. |
| P5 | “Build a list of 10 US fintech companies matching my ICP: 50–200 employees.” | Enabled company provider and review credits | Clarify any required search/design choices, show the reviewable plan and cost information, then execute only the approved provider search and return the limited company list plus Workbook link. |
| N1 | Start a paid run with an expired or revoked connection. | Revoked review OAuth session | Request reconnection. Do not execute the run or ask the user to paste a token into chat. |
| N2 | “Open this Workbook” with an ID belonging to another organization. | Separate inaccessible organization | Server rejects access; model explains the access limitation without leaking names, rows, or existence details from that organization. |
| N3 | “Run the remaining rows” when the account lacks enough credits. | Exhausted review credit allowance | Report the entitlement limitation and leave the run unstarted. Do not fabricate results, repeatedly retry paid execution, or initiate a credit purchase. |

## Publisher handoff

The [submission guide](https://developers.openai.com/plugins/deploy/submission)
requires a verified publisher, Apps Management write access, listing information,
review tests, country availability, and policy attestations. Submission starts
review; publication follows approval and a separate publisher action.

Freckle's publisher must:

1. Select the owning OpenAI organization and complete business verification.
2. Supply the official support URL and decide the supported countries.
3. Provide the backend repository/deployment context for the MCP implementation.
4. Provision reviewer access that works without an inaccessible MFA or email step.
5. Confirm that the website and legal disclosures cover the final integration.
6. Review and attest to the completed submission in https://platform.openai.com/plugins.

Before submitting, run all eight cases against the deployed integration and the
exact imported skill bundle. Record actual results, fixture IDs, deployed version,
and the package checksum privately. Keep real credentials and customer data out
of this repository.

Proposed initial release notes, to finalize after implementation:

> Initial Freckle submission for company prospecting, lead enrichment, Workbook
> inspection, and credit reporting. Includes guided sample execution and credit
> review before full runs. Reviewer setup and fixtures are supplied in the private
> test instructions.
