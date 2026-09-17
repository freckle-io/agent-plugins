# Claude Desktop automatic setup and update — 2026-09-17

## Code and fixtures

CLI helper: `freckle-io/next@5f6e420cc56cc52c4bea3f63816f9e63098685b3`.
Plugin hook: the inline SessionStart command in PR #5; existing launcher and PreToolUse hooks unchanged in the production PR.
Desktop app installed locally: 2.2553.0 (macOS ARM64).
Test branch: `codex/desktop-auto-update-e2e-20260917`.
Fixture A: plugin `1.0.906-install.1`, CLI `1.0.0-desktop-auto.1`, commit `340534b`.
Fixture B: plugin `1.0.906-install.2`, CLI `1.0.0-desktop-auto.2`, commit `09af8e12c4867a7e9a05dc369b9e153ccd77e1cd`.
Executables were compiled from the helper commit above and served from local file URLs with matching SHA-256 checksums. Only the test branch changes pins/asset URLs. No production release was published.

## Initial blocker and correction

The user's real Desktop Bash probe reported `CLAUDE_CODE_ENTRYPOINT=claude-desktop`, `DISABLE_AUTOUPDATER=1`, and no `FORCE_AUTOUPDATE_PLUGINS`. Marketplace autoUpdate alone was insufficient. A preliminary manual override experiment downloaded plugin 1.0.904-desktop.2 and the user verified CLI 1.0.0-final-e2e.2 inside a fresh Desktop session.

The new helper automatically adds `env.FORCE_AUTOUPDATE_PLUGINS="1"` only for the Desktop entrypoint and only when that setting is absent. It preserves existing override values and explicit marketplace opt-outs. The flag allows checks for all marketplaces already opted in; it is not Freckle-specific. This follows the documented updater override: https://code.claude.com/docs/en/discover-plugins#configure-auto-updates .

## Full install-path test

1. Removed the Freckle test registration and both test settings. Other user configuration was preserved.
2. The user reported running both `/plugin marketplace add freckle-io/agent-plugins#codex/desktop-auto-update-e2e-20260917` and `/plugin install freckle@freckle-plugins` in Desktop. This is user-reported command installation, not an independently observed plugin-browser UI interaction.
3. After restarting Desktop, the user's actual Bash probe reported:

```
CLAUDE_CODE_ENTRYPOINT=claude-desktop
CLAUDE_CONFIG_DIR=default
DISABLE_AUTOUPDATER=1
FORCE_AUTOUPDATE_PLUGINS=1
Resolved freckle: /Users/bwang/.local/bin/freckle
freckle v1.0.0-desktop-auto.1
User autoUpdate: True
Configured FORCE_AUTOUPDATE_PLUGINS: 1
Installed plugin: 1.0.906-install.1
Installed CLI pin: cli-desktop-auto-1
```

4. B was published to the test branch at `2026-09-17T20:08:18.444988+00:00`. No manual plugin update was run afterward. The first session remained on A; the user quit/reopened Desktop, started a fresh session, and submitted the probe with B already available.
5. The user observed B downloaded. Independently reading `~/.claude/plugins/installed_plugins.json` confirmed version `1.0.906-install.2`, commit `09af8e12c4867a7e9a05dc369b9e153ccd77e1cd`, and lastUpdated `2026-09-17T20:23:05.824Z`. Its CLI pin is `cli-desktop-auto-2`.

**Confirmed:** installation in Desktop, automatic creation of both update settings, and automatic background download of B after a fresh Desktop session.
**Final activation confirmed:** after quitting/reopening Desktop and starting a new Code session, the user supplied the actual probe output showing `CLAUDE_CODE_ENTRYPOINT=claude-desktop`, `FORCE_AUTOUPDATE_PLUGINS=1`, `freckle v1.0.0-desktop-auto.2`, installed plugin `1.0.906-install.2`, and pin `cli-desktop-auto-2`. This completes automatic setup → background download → updated CLI use in Desktop, with the separately repaired forwarder prerequisite described below. The probe read 19.6 minutes since publication at verification time; that is not the download duration (the registry recorded download earlier). Its generic restart message was stale guidance, not an additional required step.

## CLI resolution limitation

The original standalone `~/.local/bin/freckle` shadowed the plugin. It was separately removed at the user's request and replaced with the existing setup skill's standard launcher forwarder. The final install-path test retained that repaired forwarder. This is an explicit local setup prerequisite, not a new automatic feature of either PR. The hook itself uses an absolute plugin launcher path and does not rely on bare `freckle` resolution.

## Automated validation

- 307 targeted tests, typecheck, lint, and strict plugin validation passed.
- Compiled macOS smoke test with empty PATH passed: initial automatic setting creation, repeat preserving content/mtime, and explicit opt-out preserving content/mtime. Empty stdout and exit 0 verified.
- Native compiled Desktop-helper tests passed on macOS/Linux/Windows: https://github.com/freckle-io/next/actions/runs/35267697871 . Windows helper success does not establish Windows plugin bootstrap support.

## Remaining release gates

Publish the supporting CLI release, then advance the real plugin pin/checksums before merging the hook. Native Windows plugin launcher support remains unresolved. Existing stale plugin installations need one update to receive the hook. Reverting code does not remove settings already written; remove the force override separately if rolling it back, and use the marketplace toggle to disable Freckle updates.
