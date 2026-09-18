# Workflow CLI Reference

If the current request authors or changes a Workflow and you have not entered the six-step path in [../BUILD.md](../BUILD.md) or the refine path in [../REFINE.md](../REFINE.md), go back — these commands do not replace those paths; they tell you when to use them.

Org-scoped Workflow commands accept `--org-id=<org-id>` and `--token <frk_token>`. Append `--org-id=<org-id>` after the complete subcommand path; an explicit value has highest precedence over `FRECKLE_ORG_ID` and shared global config. `workflow node list` and `workflow node inspect` use only the CLI Token because the catalog is global; `workflow node preview` remains org-scoped.

## Node Catalog

List and inspect node definitions:

```bash
freckle workflow node list
freckle workflow node inspect <definition-key>
freckle workflow node inspect <definition-key> --contract
```

The YAML shapes below are abbreviated; nested schemas, types, metadata, and repeated entries are omitted.

`workflow node list` returns:

```yaml
nodes:
  - definitionKey: <definition-key>
    definitionVersion: <definition-version>
    label: <label>
    description: <optional-description>
    category: <category>
    purpose: <optional-purpose>
    creditCost: <credits>
    creditCostModel: <static-or-dynamic-or-usage_based>
```

`description` and `purpose` are omitted when unavailable.
`creditCost` and `creditCostModel` are always present, including when the price is zero. `creditCost` is the customer-facing unit price for `static` and `dynamic` models. A `static` price is charged at most once per execution and only when the node produces a billable result; an enrichment node that finds no result costs 0 credits. A `dynamic` price is charged once per billable result. For `usage_based`, the listed `creditCost` is a placeholder rather than a quote: the exact Freckle-credit charge is calculated from metered provider usage after execution.

Use the full `workflow node inspect <definition-key>` before authoring. It returns:

```yaml
definitionKey: <definition-key>
definitionVersion: <definition-version>
editor: <editor-metadata>
purpose: <optional-purpose>
creditCost: <credits>
creditCostModel: <static-or-dynamic-or-usage_based>
configSchema: <json-schema-or-null>
configUnrepresentedRules: <rules-not-expressed-in-json-schema>
contract:
  kind: static
  inputPorts: <input-port-details>
  outputs: <output-port-details>
  caseIds: <branch-case-ids>
authoring: <optional-authoring-guidance>
```

`purpose` and `authoring` are omitted when unavailable. A dynamic definition's inspect has `contract: { kind: dynamic }`. Pricing fields use the same semantics as the list response.

Inspection and preview always include complete input, output, and config schemas. Use output schemas to choose downstream field mappings. `--json` changes only the format and also works with `--contract`.

`workflow node inspect <definition-key> --contract` prints only the contract. Static contracts have port schemas and branch cases:

```yaml
kind: static
inputPorts:
  - portId: <port-id>
    label: <label>
    schema: <json-schema>
    unrepresentedRules: <rules-not-expressed-in-json-schema>
    isOptional: false
outputs:
  - outputId: <output-id>
    label: <label>
    schema: <json-schema>
    unrepresentedRules: <rules-not-expressed-in-json-schema>
    isOptional: false
caseIds: <branch-case-ids>
```

Use each input port's `schema` to construct its value: it contains enums, limits, nested `required` fields, and documented defaults. Fields absent from `required` may be omitted, including defaulted fields. The CLI simplifies safe schema patterns for readability; resolve any remaining `$ref` values against the same document's `$defs`. `isOptional` controls whether the whole port can be unbound. Output schemas describe decoded values produced by the node. `configSchema` uses the same JSON Schema format, or is null when the node has no config.

Read `unrepresentedRules` on ports and `configUnrepresentedRules` for config alongside the schemas. These list known custom checks, transformations, and opaque declarations that JSON Schema does not fully describe; runtime validation remains authoritative even when the lists are empty.

A dynamic contract cannot be resolved without node config and may contain only:

```yaml
kind: dynamic
```

Preview dynamic nodes after their config is present in the draft. Provide exactly one of `--input-json` or `--file`:

```bash
freckle workflow node preview <node-id> --file workflow.yaml
freckle workflow node preview <node-id> --input-json '<draft-json>'
```

`workflow node preview` returns the resolved contract for the requested node. Unlike inspect output, the resolved `contract` has no `kind` field:

```yaml
nodeId: <node-id>
definitionKey: <definition-key>
definitionVersion: <definition-version>
contract:
  inputPorts: <input-port-details>
  outputs: <output-port-details>
  caseIds: <branch-case-ids>
```

When a node config needs a `credentialId` — a provider connection or an `httpRequest` HTTP credential — resolve it through [../CONNECTIONS.md](../CONNECTIONS.md) before authoring.

## Saved Workflows

List and inspect saved Workflows:

```bash
freckle workflow saved list
freckle workflow saved list --org-id=<org-id>
freckle workflow saved list --all
freckle workflow saved list --archived
freckle workflow saved inspect <workflowId>
freckle workflow saved inspect <workflowId> --org-id=<org-id>
freckle workflow saved revisions list <workflowId>
freckle workflow saved revisions inspect <workflowId> <revisionId>
```

Each list row includes the Workflow's input/output `shape` when it has a published revision, and `saved inspect` embeds the full input/output `schema` — use these for reuse checks and input mappings instead of exporting drafts.

`workflow saved list` adds `costEstimate` to every Workflow row, and `workflow saved inspect <workflowId>` adds it to the top-level response:

```yaml
costEstimate:
  estimatedStaticCreditCost: <credits>
  dynamicNodeCosts:
    - nodeId: <node-id>
      definitionKey: <definition-key>
      definitionVersion: <version>
      creditCost: <per-result-credits>
      creditCostModel: dynamic
  usageBasedNodeCosts:
    - nodeId: <node-id>
      definitionKey: <definition-key>
      definitionVersion: <version>
      creditCostModel: usage_based
  description: <plain-language-estimate>
# or null when the Workflow has no saved latest revision
```

`costEstimate` is the same structured estimate returned when creating or saving a Workflow revision: static node prices are summed into `estimatedStaticCreditCost`, dynamic node unit prices are listed separately in `dynamicNodeCosts` because billable result counts are unknown until runtime, and nodes whose exact charge depends on metered provider usage are listed in `usageBasedNodeCosts`. A Workflow without a saved latest revision returns `costEstimate: null`. The estimate is a conservative maximum only when every additional dynamic result count is capped and `usageBasedNodeCosts` is empty; it is not a guaranteed bill, and a run can cost 0 credits when no node produces a billable result.

Use the default saved Workflow list for reuse discovery — it is scoped to the Active Organization, which is the only organization reuse looks at; archived Workflows are not reuse candidates unless the user explicitly asks about archived Workflows. Use `--all` only when the user explicitly asks to list saved Workflows across every organization available to the CLI token, or when step 1 is locating a named Workflow to derive the destination organization; it returns groups keyed by organization and is not part of normal reuse discovery.

Read the relevant command's help before exporting or saving:

- `freckle workflow saved get-draft --help` — export an editable draft; revision selection and file output.
- `freckle workflow saved create --help` — create a new Workflow; required inputs and returned IDs.
- `freckle workflow saved lifecycle publish --help` — add a revision to an existing Workflow; identity and publication effects.

Update saved Workflow metadata or lifecycle state:

```bash
freckle workflow saved lifecycle update <workflowId> --label "<label>" --description "<description>"
freckle workflow saved archive <workflowId>
freckle workflow saved unarchive <workflowId>
```

## Run Saved Workflows

Follow invoke → watch → inspect, reading each command's help before using it:

1. `freckle workflow saved invoke --help` — inputs, start responses, and retry behavior. Resolve any start rejection before continuing.
2. `freckle workflow saved runs watch --help` — waiting, limits, and exit behavior.
3. `freckle workflow saved runs inspect --help` — results and failure details.

Keep the exact accepted Run IDs through watching and inspection; report completion only after they reach terminal states and their results have been inspected. For run history and filtering, read `freckle workflow saved runs list --help`.

Optional outputs from unselected branches may be omitted from run outputs.

## Run Errors

A failed run or node carries a product-safe error:

```yaml
error:
  kind: <error-code>
  category: <optional-failure-category>
  message: <human-readable-explanation>
  details: <optional-safe-facts>
```

Choose how to react from `category` alone:

- `invalid_config` — the node's config is wrong. Fix the workflow draft and republish.
- `invalid_input` — a bound input value is wrong or missing. Fix the upstream data or bindings.
- `connection` — the Integration Connection has a problem (revoked credentials, missing scopes, or a rate limit tied to that connection). Reconnect the Integration Connection or resolve the limit in the Integration; see [../CONNECTIONS.md](../CONNECTIONS.md).
- `provider_unavailable` — a transient upstream outage. Retry the run; no workflow change is needed. Any `kind` ending in `.runtime.provider_unavailable` means this.
- `internal` — Freckle hit an internal error. The `kind` is always `freckle.node.internal`. Retry the run; if it persists, tell the user to contact Freckle support with the run id from `details`.

Node-specific `kind` values and their fixes are documented per node in `workflow node inspect <definition-key>` under `authoring.commonDiagnostics`. `category` is optional; when it is absent, use `kind` and `message`.

**Sample gate:** before running a saved Workflow across user rows, check the row count. Read [credit-cost.md](credit-cost.md) and return its Credit Forecast Summary after the first 10 input rows’ runs reach terminal states.

- 20 or fewer rows: run all rows and inspect each run until terminal.
- More than 20 rows: run the first 10 representative rows, inspect results until terminal, show those preview inputs and results plus the Credit Forecast Summary to the user, and ask whether to continue before running the rest.

After processing rows, report final results as a Markdown table: every row when there are 20 or fewer; 10 representative rows, clearly labeled as a sample, when there are more.
