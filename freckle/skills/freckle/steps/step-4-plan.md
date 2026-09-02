# Step 4: Plan Accepted

Present the plan and get explicit approval. Once accepted, the plan is **frozen**.

- Open the plan message with the plain-English objective restatement from step 2 — this is where the user confirms it, together with the plan.
- **Serve a minimal plan** (under ~1,500 characters): (1) the assumptions you made, as short bullets; (2) one line describing the flow, e.g. "CSV → Apollo company enrich (AI Ark fallback) → funding lookup → fit score → new Workbook"; (3) the result-fields table below — this is the contract; (4) one line of cost: credits per row × rows ≈ total. No workbook picture, diagram, or mapping table unless the user asks; offer them in one closing sentence. Approval of this plan freezes the design.
- Render a Markdown table of planned result fields with columns `Data point` and `Source`; `Source` names the node that produces the field. Enumerate each top-level field of the planned typed object output as its own row — these are the output Dataset's columns. If unfold is planned, say each item of the named output becomes its own row and sibling outputs are not collected.
- Apply [credit-cost.md](../workflow/credit-cost.md) immediately below that table and render its **Credit Cost Summary** for approval.
- When Push is planned, render a `Dataset handoffs` table with destination label/id, producing node, complete object-array source, cataloged fields, and downstream readers. Its producing Workflow's result-fields table contains the Push receipt, not a duplicate people array.
- State the reuse decision from step 2 as part of the plan — feed-and-run, wire an existing Workflow, clone-and-extend of a named saved Workflow (with what is preserved and what changes), or start new.
- State the run intent from step 2 as part of the plan — what gets saved or published, which rows run, and whether the connection flips to automatic afterward.
- Ask for explicit confirmation that the user is fully okay with this exact plan before any building begins. Describe what approval triggers accurately: you will set up the Workbook and load the data, build and validate the Workflow, connect it, and run without asking again — the only later pause is the sample gate on more than 20 rows.

## Frozen

After acceptance, the drawn shape is binding: the Workbook picture, diagram, mapping, result-fields table, Credit Cost Summary, and Dataset handoffs pin the datasets, the Push destinations with their catalogs and downstream readers, the mapping, the trigger policy, the providers and their ordering, the branch structure, the Research Agent role, failure behavior, every end state, and the stated credit maximums or formulas. A draft that differs from that shape in any pinned element — even by simplification, substitution, or a temporary shortcut — is a plan change: stop and get explicit approval for a revised plan first. A planned fallback is a rung, not a replacement Workflow. Plumbing nodes are yours to add freely — collectors, switches, and JS nodes as the draft needs — as long as they implement exactly the drawn branches.

**Completion** — every box checked:

- [ ] The Workbook picture, diagram (in the format matched to the surface), mapping table, result-fields table, Credit Cost Summary, and any Dataset handoffs table are rendered in the plan message.
- [ ] The user explicitly confirmed the full plan — destination org, Workbook destination, Push destinations, downstream readers, trigger policies, reuse choice, run intent, and the stated credit maximum or uncapped formula.
- [ ] If the user changed anything, you returned to the earliest affected step and re-confirmed the revised plan before building.

Completion met → read [step-5-draft.md](step-5-draft.md).
