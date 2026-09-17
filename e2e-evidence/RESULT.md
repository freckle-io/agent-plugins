# Final private-hook E2E — 2026-09-17

PASS: real Claude Code 2.1.270 on macOS ARM64 enabled auto-update itself, downloaded a newer plugin in the background, and ran its newer pinned CLI after restart. No manual update command was used.

## Exact code and isolation

- CLI source: `freckle-io/next@68f74c5a3d8802087fd26aee069040eaa3fd9957` (PR #1509 final private invocation and installed-plugin guard).
- Plugin: PR #5 head `87a3cbddecd76694002710b59093585c5d463ae7`.
- Fixture A: `42d1be745b77c2121bf12ffee43ef4ae4d4126dd`, plugin `1.0.903-e2e.1`, CLI `1.0.0-final-e2e.1`.
- Fixture B: `e134ea0690486d8bdd5946ec025dcd341c9bab71`, plugin `1.0.903-e2e.2`, CLI `1.0.0-final-e2e.2`.
- Fresh HOME and Claude config under `/tmp/freckle-final-e2e`; personal Claude settings were not replaced.
- Allowed PATH contained shell/Git/download/checksum utilities, but no node, python3, python, bun, or jq. Bash login-shell configuration preserved that PATH. See actual [Bash tool results](bash-evidence.json).
- Both standalone binaries were compiled from the same final CLI source with distinct test release identities. Fixture launcher changed only its release URL to a localhost asset server; no production release was published. Pins, checksums, and plugin versions differed between fixtures. Both cold-download cache hashes matched the expected checksums.

## Steps and results

1. Added `freckle-io/agent-plugins#codex/final-auto-update-e2e-20260917` through `claude plugin marketplace add`; installed using `claude plugin install freckle@freckle-plugins`. User settings initially lacked `autoUpdate`.
2. Started Claude. The real SessionStart hook downloaded CLI A and logged at `18:03:28.559Z`: `Freckle: enabled Claude marketplace auto-update.` User `settings.json` gained `extraKnownMarketplaces.freckle-plugins.autoUpdate: true`, preserving the existing GitHub branch source and enabled-plugin entry. No model edited settings.
3. Submitted a prompt only to run `command -v node python3 python bun jq freckle` and `freckle --version`. Only the plugin launcher resolved; the version was `freckle v1.0.0-final-e2e.1`.
4. Pushed fixture B to the test branch while that session remained open. No update command was run.
5. At `18:10:32.104Z`, Claude logged: `Plugin autoupdate: updated freckle@freckle-plugins from 1.0.903-e2e.1 to 1.0.903-e2e.2`. Its installed registry advanced to fixture B. This was approximately six minutes after the first prompt, an observation rather than a timing guarantee.
6. Restarted Claude normally. SessionStart cold-downloaded CLI B, and an actual Bash tool call returned `freckle v1.0.0-final-e2e.2`. No Python/Node or other JSON utility resolved. User settings content AND modification time remained unchanged after the already-enabled hook.
7. `claude plugin validate ./freckle --strict` passed for the production PR and fixture A.

## Other verification

[Final native compiled-command CI](https://github.com/freckle-io/next/actions/runs/35256189403) passed on macOS, Linux, and Windows with an empty PATH. It verifies absent-plugin no-write behavior, successful enablement, idempotence, and malformed-settings recovery with empty stdout and successful exit status.

## Limits and release prerequisites

This proves the final automatic hook-to-background-update-to-CLI-activation chain on macOS using branch fixtures and locally served executable assets. It does not prove a yet-unpublished production CLI release or Windows plugin bootstrap. Native compiled CLI support is distinct from plugin launcher support: the current launcher supports macOS ARM64 and Linux x64, and rejects native Windows.

Before merging the plugin hook, release CLI PR #1509 and advance the real pin/checksums. Existing stale installations need one update to receive the hook. New installations need only the marketplace-add and plugin-install commands. Background timing is Claude-controlled; this test establishes successful attempts, not a guaranteed update interval. Reverting code does not switch an already-enabled marketplace setting back off.
