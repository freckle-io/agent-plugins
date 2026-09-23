# Freckle Integration Connections

Use this reference when the user wants to connect provider credentials or use their own API key in a Workflow. Match supported provider nodes to [Provider connections](#provider-connections), including [OpenAI for Research Agent](#openai-for-research-agent) and [Anthropic for Research Agent](#anthropic-for-research-agent); use [Custom HTTP APIs](#custom-http-apis) for other APIs.

## Provider connections

List connectable integrations and inspect public credential summaries:

```bash
freckle connections list --org-id=<org-id>
freckle connections list --json --org-id=<org-id>
freckle connections show hubspot --org-id=<org-id>
freckle connections show heyreach --org-id=<org-id>
freckle connections show lemlist --json --org-id=<org-id>
freckle connections show twain --json --org-id=<org-id>
freckle connections show hubspot --json --org-id=<org-id>
freckle connections show contactout --json --org-id=<org-id>
freckle connections show apify --json --org-id=<org-id>
freckle connections show openai --json --org-id=<org-id>
```

When a Workflow node config accepts a `credentialId`, inspect its node contract to identify the integration
and whether the node supports managed access. Select an authorized credential from
`freckle connections show <integration> --json --org-id=<org-id>` and set that exact ID while preserving the node's
other config fields. Select only a credential whose `status` is exactly `authorized`; `connected` and
`credentialCount` in list output do not imply usability. If the selected credential is unavailable, ask the user to reconnect or select another;
use managed access only when the node contract supports it and the user chooses it. Use the Workflow cost
estimate for Freckle credit cost; charges from a customer-owned provider account are separate.

Apify Run Actor supports Freckle-managed access and BYOK. Omit `credentialId` for managed access; set the exact
authorized Apify `credentialId` for BYOK. Apply the [Workflow credit-cost rules](workflow/credit-cost.md) for the
Freckle credit calculation and customer-owned provider charges. Keep a selected BYOK
connection authorized until result collection completes; disabling, deleting, or rotating it during a run may
prevent Freckle from collecting that run's results.

ContactOut Find Phone Number and Find Personal Email also support both: omit `credentialId` for managed access, or set an authorized
ContactOut `credentialId` for BYOK. BYOK uses zero Freckle credits.

Twain Generate Outreach requires an authorized Twain Integration Connection. Use its `credentialId` and the
campaign ID copied from Twain's campaign “...” menu. The node returns messages and research in the Workflow;
it uses zero Freckle credits, while Twain may charge the connected account. It does not add the contact to
the Twain campaign.

Open the Freckle web app to connect one supported integration:

```bash
freckle connections connect heyreach --org-id=<org-id>
freckle connections connect hubspot --org-id=<org-id>
freckle connections connect salesforce --org-id=<org-id>
freckle connections connect instantly --org-id=<org-id>
freckle connections connect lemlist --org-id=<org-id>
freckle connections connect twain --org-id=<org-id>
freckle connections connect slack --org-id=<org-id>
freckle connections connect supabase --org-id=<org-id>
freckle connections connect contactout --org-id=<org-id>
freckle connections connect apify --org-id=<org-id>
freckle connections connect openai --org-id=<org-id>
freckle connections connect anthropic --org-id=<org-id>
```

The command prints the URL and tries to open a browser.

Both Apollo Find People nodes use Freckle-provided access and do not require a customer Apollo connection or `credentialId`; see [workflow/apollo-find-people.md](workflow/apollo-find-people.md).

### OpenAI for Research Agent

OpenAI is optional BYOK for Research Agent. To connect a key, run `freckle connections connect openai --org-id=<org-id>`; this opens that workspace's Settings → Integrations with OpenAI selected. The user enters, validates, and saves the key in the authenticated browser form. Keep the key out of chat, CLI arguments, URLs, logs, and Workflow JSON; direct the user to the form if they offer to paste it elsewhere.

After saving, run `freckle connections show openai --json --org-id=<org-id>` again and select the exact authorized `credentialId`. This command returns public metadata only. When configuring BYOK, follow the [Research Agent model contract](workflow/research-agent.md) for the supported provider/model and credit behavior. A saved connection confirms authentication and permission to list models; it does not establish later model access, Responses permission, quota, or billing availability.

- [ ] A fresh OpenAI connection summary in the requested workspace has `status: authorized`.
- [ ] The selected credential ID comes from that summary; any Research Agent BYOK config follows its model contract.

## Anthropic for Research Agent

Anthropic is BYOK-only for Research Agent. To connect a key, run `freckle connections connect anthropic --org-id=<org-id>`; this opens that workspace's Settings → Integrations with Anthropic selected. The user enters, validates, and saves the key in the authenticated browser form. Keep the key out of chat, CLI arguments, URLs, logs, and Workflow JSON; direct the user to the form if they offer to paste it elsewhere.

After saving, run `freckle connections show anthropic --json --org-id=<org-id>` again and select the exact authorized `credentialId`. This command returns public metadata only. When configuring BYOK, follow the [Research Agent model contract](workflow/research-agent.md) for the supported provider/model and credit behavior. A saved connection confirms authentication and permission to list models; it does not establish later model access, Messages permission, quota, or billing availability.

- [ ] A fresh Anthropic connection summary in the requested workspace has `status: authorized`.
- [ ] The selected credential ID comes from that summary; any Research Agent BYOK config follows its model contract.

## Custom HTTP APIs

Users voice this intent in their own words — "use my own API key", "use tool X instead", "call our internal API", "hit the vendor's endpoint" — never in Freckle terms. Inspect the node catalog first: use a supported provider's BYOK connection when its contract covers the request, including OpenAI for Research Agent. For other APIs, use an `httpRequest` node plus a Workspace HTTP credential. HTTP credentials are separate from the provider Integration Connections above; connecting a provider never satisfies an `httpRequest` node, and an HTTP credential never satisfies a provider node.

### Matching a credential to the request

Resolve an `httpRequest` node's `credentialId` against its destination:

1. Render the request's static scheme, hostname, and port from the node config.
2. Run `freckle http-credentials list --json` and match that destination against each credential's public `allowedDomains` policy. An `all_public_domains` policy matches any public HTTP(S) destination. A `restricted` policy matches when a target's scheme, port, and hostname match (an omitted port means 443 for HTTPS and 80 for HTTP); an exact target matches only that host, and `includeSubdomains: true` also matches hostname labels below it, never lookalike suffixes.
3. Apply the match count: exactly one authorized match → select it automatically; multiple matches → ask the user to choose; none → tell the user a credential for that destination is needed and open the [setup form](#browser-only-secret-entry).

Put only the saved `credentialId` from a fresh list result in the Workflow config.

### Browser-only secret entry

The secret is entered once, in the authenticated browser form. Chat, command arguments, URLs, logs, and Workflow JSON carry only public fields and the credential ID; when the user offers to paste a key anywhere else, point them to the browser form instead.

Open the Workspace HTTP credential form with public prefill. The user reviews it and enters the secret in the
authenticated browser:

```bash
freckle http-credentials add \
  --label "Production API" \
  --auth-type bearer \
  --targets https://api.example.com \
  --json

freckle http-credentials add \
  --label "Vendor API" \
  --auth-type header \
  --key X-API-Key \
  --targets https://api.vendor.example \
  --json
```

Use `--auth-type query --key <name>` only when the provider requires query authentication. `--targets` accepts
comma-separated exact `http://` or `https://` origins; add `--include-subdomains` only when every target needs it.
Restricted targets are the default. `--all-domains` is an explicit exception that the user must review and confirm
in the browser; it still permits only publicly routable HTTP API destinations.

After the user saves the form, re-run `freckle http-credentials list --json` and select the new credential through the [matching policy](#matching-a-credential-to-the-request).
