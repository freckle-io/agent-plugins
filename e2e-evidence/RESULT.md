# PASS: compiled-hook end-to-end update without Python/Node

September 16, 2026. macOS ARM64, Claude Code 2.1.270.

## Result

A fresh Claude plugin installation ran the compiled CLI from SessionStart, enabled its marketplace auto-update setting, automatically received plugin B in the same session, and ran CLI B after a normal restart. No manual update command, settings edit, model-driven setup, production CLI publication, or default-branch push was used.

Only `freckle-io/agent-plugins` test branch `codex/no-runtime-e2e-20260916` was pushed. `next/main`, `next/dev`, and plugin main were untouched.

| Check | A | B |
| --- | --- | --- |
| Plugin | 1.0.902-e2e.1 | 1.0.902-e2e.2 |
| Plugin commit | cef4e3f | 5890b2f72ec8540e98e46a5dc366735a2c073a6d |
| CLI pin | cli-no-runtime-e2e-1 | cli-no-runtime-e2e-2 |
| Actual Bash `freckle --version` | freckle v1.0.0-e2e.1 | freckle v1.0.0-e2e.2 |
| CLI SHA-256 | 2a7313e40cf03f727c665baa250ad8654e0a45c1e39c8a4864bf17cb12da3f02 | b81d3d9ce66157da1051007c7e99e918320a0c127f0a20e61ef31d2e8ccd8842 |

## Method

1. Built two standalone CLI binaries from supporting CLI PR #1509 commit `16ac7d5fa03e5ed497f84166c79e4bc0a2bfd046`, using the normal executable build script and distinct embedded test release identities. Application source is the same; identities differ to prove binary selection.
2. Served the assets at `http://127.0.0.1:18769`. Only the fixture launcher's release URL differs from the production launcher. The launcher still downloads, verifies the shipped checksum, caches the pinned binary, and disables CLI self-update.
3. Replaced the Python/Node hook in the fixture with this script:

```sh
#!/bin/sh
# Use the pinned standalone CLI; no external JSON runtime is needed.
"${CLAUDE_PLUGIN_ROOT}/bin/freckle" config enable-claude-auto-update >&2 || :
exit 0
```

The SessionStart timeout is 120 seconds to allow a cold CLI download. Existing PreToolUse hooks and skills are unchanged.

4. Used a fresh HOME, CLAUDE_CONFIG_DIR, and FRECKLE_CONFIG_HOME under this evidence directory. PATH contains an allowlist of shell, Git, download, checksum, and basic OS utilities, with no Node, Python, Bun, or jq. The isolated login-shell profile preserves that PATH. Python is used by the *external test harness/server*, never by Claude's hook or the downloaded CLI.
5. Ran the real marketplace-add and plugin-install commands against the GitHub test branch. Their initial settings contained the branch source and enabled plugin, with **no autoUpdate override**. No setting was manually seeded to enable updates. CLI cache was empty.
6. Started interactive Claude and trusted only the test project. Before any model prompt, SessionStart downloaded A and wrote autoUpdate true.
7. Submitted a prompt requesting only two read-only Bash commands: `command -v node python3 python bun jq freckle` and `freckle --version`. Actual tool results showed only the plugin's A launcher on PATH and version e2e.1. The model did not edit settings or invoke the helper.
8. Pushed fixture B to the same test branch, changing only the plugin version, CLI pin, and checksum. Left Claude open. About 85 seconds after the first prompt submission, its real background updater installed B. No `marketplace update` or `plugin update` command was run.
9. Restarted Claude normally. B's SessionStart downloaded and checksum-verified binary B. The same two Bash commands resolved the B launcher and returned e2e.2. Settings content **and nanosecond mtime** were unchanged on restart, confirming the helper was a no-op once enabled.
10. Checked both cached executable hashes against the fixture checksums. `claude plugin validate ./freckle --strict` and shell syntax validation passed. Stopped the test sessions and localhost server afterward.

## Primary evidence

Before-session debug log:

```text
2026-09-16T22:22:01.922Z Hook SessionStart:startup success:
freckle: installing CLI cli-no-runtime-e2e-1 (darwin-arm64)...
Freckle: enabled Claude marketplace auto-update.
2026-09-16T22:23:38.202Z Plugin autoupdate: checking installed plugins
2026-09-16T22:23:38.222Z Plugin autoupdate: updated freckle@freckle-plugins from 1.0.902-e2e.1 to 1.0.902-e2e.2
```

Restart debug log:

```text
2026-09-16T22:24:52.205Z Hook SessionStart:startup success:
freckle: installing CLI cli-no-runtime-e2e-2 (darwin-arm64)...
```

Actual Bash tool-use/result pairs: [all-bash-evidence.json](all-bash-evidence.json).
Other files: `before.log`, `after.log`, `builds.json`, initial `before-*.json` records, updated marketplace/plugin records, and `settings-before-restart.json`.

## Limits / remaining rollout work

- This is a full **macOS** Claude plugin E2E result. Native CLI-only empty-PATH checks separately passed on macOS, Linux, and Windows: https://github.com/freckle-io/next/actions/runs/35147749813. They do not establish Windows plugin bootstrap; Windows hook/launcher wiring remains unimplemented.
- The test branch contains a localhost URL and test release pins and must not be merged as production code. Production adoption still requires releasing the CLI helper and pinning the plugin to that real release with matching checksums.
- No production CDN/release publication was tested; the real downloader and checksum path were tested against localhost.
- The observed ~85-second delay is not a polling-frequency guarantee. Existing stale installations still need to receive the new hook once. Administrator settings and network failures can prevent updates.
