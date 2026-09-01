# Research Agent

Research Agent (`researchAgent` in the node catalog) does open-ended web research. Each Research Agent node plays one of two roles, and a Workflow can carry several — one per job (recover a URL mid-waterfall, score at the end). The role choice is a plan-shape decision made during contract mapping.

Contract facts that shape the plan (inspect `researchAgent` for the full contract):

- Its config requires `prompt`, `inputs`, and `resultType`; `webResearch` is optional, and only an explicit `false` disables web research.
- Each `inputs` entry requires `portId`, `label`, and `type` (`description` is optional).
- `resultType` must resolve to an exact object type: no optional fields, no `unknown`, no additional properties, no tagged unions. Declare values research may not find as `nullable<...>` fields. This constrains the result-fields table you plan in step 4.
- It emits `result` (typed by `resultType`), `steps`, and an optional `sources` output port; it selects no branch cases.
- A "not found" outcome lives inside a successful `result`; a runtime node failure fails the Workflow Run.

**Decision rule:** inspect the node catalog first. If a structured provider's contract covers the objective, build a waterfall with Research Agent as the backstop. If no structured provider covers the data at all, Research Agent is primary — there is no waterfall to fall out of.

## Backstop: final fallback in a waterfall

The last rung of a [waterfall](waterfall.md), running only after structured providers fail or return insufficient data.

- Activate it from the last structured provider's insufficiency branch.
- Plan what it should attempt: the concrete question it must answer and the fields it must fill, not "research the row".
- Its output converges through the same collector as the structured fallbacks.
- **Exception — contact info.** Research Agent cannot reliably dig up phone numbers or email addresses from the open web, so a contact-info waterfall ends at its last structured provider, and its all-fallbacks-failed path emits the miss. Everything else — titles, companies, domains, URLs, firmographics, qualitative facts — backstops fine.

## Primary: no structured provider fits

When the requested data has no obvious integration — niche facts, qualitative judgments, anything the catalog's structured providers do not contract for — use Research Agent as the primary enrichment node.

- It stands alone: a provider whose contract does not match the objective is noise, not a rung, so a token waterfall of ill-fitting providers adds nothing.
- Still plan failure behavior: what the Workflow emits when research comes up empty.
