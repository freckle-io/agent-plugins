# Freckle MCP experiment

This plugin bundles an MCP connection and a Freckle skill rewritten to use its tools. It does not bundle, install, or invoke the Freckle CLI. The original `freckle/` plugin remains the CLI baseline.

The companion server is in `freckle-io/next`, branch `codex/full-mcp`, mounted alongside Rep MCP at `/mcp/full`. Start that branch's ordinary HTTP API with its development configuration. No separate service or migration is required. Rep remains at `/mcp`.

The checked-in `.mcp.json` points to `http://localhost:4003/mcp/full` for this experiment. For a deployed dev instance, change its `url` to that instance's HTTPS origin plus `/mcp/full`; do not point at production for evaluation. Sign in using the client's OAuth flow and choose the evaluation Workspace. Full MCP allows Builder/Admin roles; sales reps use Rep MCP instead. The endpoint is not assumed to be deployed merely because this branch exists.

Load `freckle-mcp/` as a local plugin in Claude Code or Codex, or select `freckle-mcp` from this branch's marketplace. Claude Desktop's remote MCP connection can use the same URL; the skill must also be made available to that client. Localhost works for locally executing clients; a cloud client requires a reachable dev HTTPS endpoint. Plugin loading/OAuth in desktop clients has not been manually exercised in this change.

Both plugin manifests reference `.mcp.json` and `skills/`. There are no CLI hooks or shell wrappers. Tool names in the skill omit client-added namespace prefixes.

Validate the package:

```sh
python3 scripts/validate-mcp-plugin.py
```

The evaluation is intentionally deferred. Compare **MCP plugin + MCP skill** against **CLI plugin + CLI skill**, with GPT 6.1 Sol Codex on the same cases and frozen product revision, and no Freckle CLI accessible to the MCP actor. Keep raw evidence in `freckle-evals`. Attribute every failure to **skill**, **missing tool**, **tool design**, **product bug**, **case bug**, or **model**; retain both skill and tool causes when evidence supports both. Do not report pass rates/cost improvements before matched runs exist.
