# Connections and credentials

Use `integrationCredentials_list` for public credential summaries and filter by the integration. Select only `status: authorized`; connected/count metadata alone does not mean a credential is usable. Inspect the node contract to learn the provider and whether managed access is supported. Preserve the selected credentialId and other config. Never switch to managed access silently after a BYOK failure.

Use `connections_setup` with the integration identifier to return the current Workspace's authenticated browser form. The user enters and saves secrets there. Refresh the list afterward. No secret goes in chat, MCP arguments, URLs, logs or Workflow JSON. A connection verifies authentication, not future model permissions, quota or billing.

Apify and ContactOut can offer managed access and BYOK when their current node contracts say so. Keep BYOK authorized until result collection completes. Apollo people nodes use managed access without a customer Apollo credential. Customer-owned provider charges are separate from Freckle credits.

## OpenAI for Research Agent

Use `connections_setup` for openai, then select its exact authorized credentialId. Read [workflow/research-agent.md](workflow/research-agent.md) and inspect the current researchAgent contract before choosing model/provider/config; available pairs may change.

## Anthropic for Research Agent

Use the anthropic browser form and authorized summary, then the current researchAgent contract. Never infer Messages/model access from successful connection alone.

## Custom HTTP APIs

Prefer supported provider BYOK nodes when they meet the goal. Other APIs use httpRequest plus an HTTP credential. A provider connection cannot substitute for an HTTP credential or vice versa.

Match the rendered static scheme/host/port to public allowedDomains. A restricted target matches exact host and protocol/port (443 HTTPS/80 HTTP defaults); includeSubdomains matches DNS labels, never lookalike suffixes. all_public_domains covers public HTTP(S) destinations. Exactly one authorized match can be selected automatically; multiple require a choice; no match needs `connections_setup` for http. The user reviews destination/auth placement and enters the secret in the browser. Only its saved credentialId enters Workflow config.
