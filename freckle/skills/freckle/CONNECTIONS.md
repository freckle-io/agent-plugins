# Freckle Integration Connections

Use this reference when the user wants to connect provider credentials, or wants a Workflow to call an outside API with their own key — see [Custom HTTP APIs](#custom-http-apis) for how that intent sounds.

## Provider connections

List connectable integrations and inspect public credential summaries:

```bash
freckle connections list
freckle connections list --json
freckle connections show hubspot
freckle connections show heyreach
freckle connections show hubspot --json
freckle connections show contactout --json
freckle connections show apify --json
```

When a Workflow node config accepts a `credentialId`, inspect its node contract to identify the integration
and whether the node supports managed access. Select an authorized credential from
`freckle connections show <integration> --json` and set that exact ID while preserving the node's
other config fields. If the selected credential is unavailable, ask the user to reconnect or select another;
use managed access only when the node contract supports it and the user chooses it. Use the Workflow cost
estimate for Freckle credit cost; charges from a customer-owned provider account are separate.

Apify Run Actor supports Freckle-managed access and BYOK. Omit `credentialId` for managed access; set the exact
authorized Apify `credentialId` for BYOK. Apply the [Workflow credit-cost rules](workflow/credit-cost.md) for its
paid-plan requirement, Freckle credit calculation, and customer-owned provider charges. Keep a selected BYOK
connection authorized until result collection completes; disabling, deleting, or rotating it during a run may
prevent Freckle from collecting that run's results.

Open the Freckle web app to connect one supported integration:

```bash
freckle connections connect heyreach
freckle connections connect hubspot
freckle connections connect instantly
freckle connections connect slack
freckle connections connect supabase
freckle connections connect contactout
freckle connections connect apify
```

The command prints the URL and tries to open a browser.

Apollo Find People currently uses Freckle-provided access and does not require a customer Apollo connection or `credentialId`; see [workflow/apollo-find-people.md](workflow/apollo-find-people.md).

## Custom HTTP APIs

Users voice this intent in their own words — "use my own API key", "use tool X instead", "call our internal API", "hit the vendor's endpoint" — never in Freckle terms. Any request to reach an API with the user's own key means an `httpRequest` node plus a Workspace HTTP credential. HTTP credentials are separate from the provider Integration Connections above; connecting a provider never satisfies an `httpRequest` node, and an HTTP credential never satisfies a provider node.

### Matching a credential to the request

Resolve an `httpRequest` node's `credentialId` against its destination:

1. Render the request's static scheme, hostname, and port from the node config.
2. Run `freckle http-credentials list --json` and match that destination against each credential's public `allowedDomains` targets. An exact target matches only that host; `includeSubdomains: true` also matches hostname labels below it, never lookalike suffixes.
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
