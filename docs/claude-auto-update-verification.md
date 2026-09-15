# Claude Code marketplace auto-update verification

Tested on macOS with Claude Code **2.1.270**, 2026-09-15.

## Proven mechanism

`extraKnownMarketplaces.freckle-plugins.autoUpdate: true` is honored in **user**
settings (`~/.claude/settings.json`), not only managed settings. With a custom
`CLAUDE_CONFIG_DIR`, the user settings file is `$CLAUDE_CONFIG_DIR/settings.json`.

1. Used a new HOME at `/tmp/freckle-autoupdate/home`, with `CLAUDE_CONFIG_DIR`
   pointing to its `.claude` directory. The real HOME and `~/.claude` were never
   moved or modified; no backup/restore of the live configuration was necessary.
2. Ran `claude plugin marketplace add freckle-io/agent-plugins`.
   Claude wrote the GitHub source into user `extraKnownMarketplaces` and into
   `plugins/known_marketplaces.json`. Neither entry contained `autoUpdate`.
3. Added `autoUpdate: true` only to the user settings entry. Merely running
   `claude plugin marketplace list --json` did not synchronize the registry.
4. Started an interactive session. Claude copied `autoUpdate: true` into
   `plugins/known_marketplaces.json`. In `/plugin` → Marketplaces →
   freckle-plugins, the UI displayed **Disable auto-update** and:

   > Auto-update enabled. Claude Code will automatically update this marketplace and its installed plugins.

5. Selected **Disable auto-update**. Both files changed to `autoUpdate: false`.
   Selected **Enable auto-update**. Both files changed back to `true`.

The hook therefore writes the user declaration and lets Claude maintain the
internal marketplace registry. It preserves an existing source, including a
custom ref; it supplies the official GitHub source only when missing.
The setting is the idempotency marker, with no separate permanent stamp.

Reference: [Claude Code auto-update documentation](https://code.claude.com/docs/en/discover-plugins#configure-auto-updates).
The observations above were verified against the running CLI and its UI.
Inspection of the installed 2.1.270 executable also showed a settings-to-registry
sync and an updater that checks the declared `autoUpdate` value before the
registry/default value.

## SessionStart and installed CLI update

The repository has no Git tags. The previous CLI release pin is represented by
commit `97d4db4d8979a51f2b48e0b9d176ea2d08e7e83b`:
plugin `1.0.354`, CLI pin `cli-v1.0.0-r354-762e4de`.
The next published commit is `99f988e8e807e9075cc4b52053cdf8d35e44a995`:
plugin `1.0.355`, CLI pin `cli-v1.0.0-r355-1053a5c`.

Test procedure and results:

1. Removed `autoUpdate` from both test configuration files. Fetched history into
   the isolated marketplace cache and checked out `97d4db4`. Installed
   `freckle@freckle-plugins` from that cached catalog. Network access was disabled
   for this install so Claude could not refresh it to latest; Claude explicitly
   reported installing from the cached catalog. The installed registry recorded
   version `1.0.354` and commit `97d4db4`.
2. Copied only this PR's `hooks/hooks.json` and `hooks/enable-auto-update.sh` into
   that installed test plugin. **This is a test overlay**, necessary because the
   historical release cannot contain a new hook. Did not edit its manifest
   version, launcher, CLI pin, skills, or PreToolUse hooks.
3. Started an ordinary interactive Claude session. Completed the test HOME's
   normal onboarding/workspace trust. Sent no model prompt. Debug output:

   ```text
   Registered 3 hooks from 1 plugins
   "Hook SessionStart:startup (SessionStart) success:\nFreckle: enabled marketplace auto-update."
   ```

   User settings now contained `autoUpdate: true`; the installed CLI pin still
   read `cli-v1.0.0-r354-762e4de`. The three registered hooks include the two
   unchanged inline PreToolUse entries and the new SessionStart entry.
4. Started another session. The setting remained enabled and Claude's registry
   contained `autoUpdate: true`. Did not wait out the background updater's
   randomized delay (the installed executable uses up to 600,000 ms).
5. Used the manual fallback:

   ```sh
   claude plugin marketplace update freckle-plugins
   claude plugin update freckle@freckle-plugins
   ```

   The first command refreshed the catalog to `r355` but **did not change the
   installed plugin**. The second reported:

   ```text
   ✔ Plugin "freckle" updated from 1.0.354 to 1.0.355 for scope user. Restart to apply changes.
   ```

   `installed_plugins.json` now pointed to the `1.0.355` cache, commit `99f988e`.
   Reading that installation's `bin/cli-version` returned
   `cli-v1.0.0-r355-1053a5c`. No local CLI-pin or version bump was used to produce
   this advance. Background download completion was not tested; the setting,
   UI, real SessionStart, and explicit update path were tested.

## Follow-up: when the background check is scheduled

The Slack discussion from August 25–26 conflated unsupported updates with
updates being disabled by default. Third-party marketplace background updates
are supported in the tested version; the old setup guide alone did not guarantee
that every installation enabled them. PR #5 was still unmerged during this check,
and the hook was absent from `origin/main`.

A follow-up test left an interactive 2.1.270 session idle for over ten minutes
with `autoUpdate: true` in both settings and the registry. No updater attempt
appeared. Inspection of the installed executable explains why: `markSubmit()`
calls background housekeeping on the **first prompt submission**; housekeeping
starts the plugin updater, which selects eligible marketplaces and then waits a
random delay of up to ten minutes. Merely opening an idle session does not start
that timer in this version. The delay is not a promise to poll every ten minutes.

Submitted a minimal prompt ("Reply OK only. Do not use tools.") to exercise this
normal session path. The hook had already written the setting before this prompt;
no model decision or tool use enables auto-update. Checked the remaining gates:

- Freckle is enabled and its GitHub marketplace has `autoUpdate: true`.
- `DISABLE_AUTOUPDATER`, `DISABLE_UPDATES`,
  `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, and `CLAUDE_CODE_SIMPLE` are unset.
- No remote managed restriction or user `disableAllHooks` is configured in the
  isolated test. The hook ran successfully.
- The marketplace uses the normal repository source, with no command/archive
  helper or pinned ref that would exclude it from the ordinary updater.

This verifies eligibility and the scheduling path; it does not establish a
completed background download. Normal network or administrator restrictions can
still prevent updates on a particular customer's machine. Updated plugin files
load on reload or the next session, rather than replacing a running session's
already-loaded skills immediately.

## Automated checks

- `python3 -m unittest discover -s tests -v`: passed. Exercises Python and Node
  separately, first run, repeat-run bytes/mtime preservation, preservation of
  other settings/marketplaces/source refs, malformed JSON/wrong types, file
  modes, symlinks, lock contention, missing interpreters, custom config directory,
  default HOME, exit status, and stdout silence.
- `claude plugin validate ./freckle --strict`: passed.
- `sh -n freckle/hooks/enable-auto-update.sh` and `git diff --check`: passed.
- The supplemental Codex plugin-creator validator reports five errors for the
  existing Codex manifest (hooks field and missing interface metadata). The
  exact same errors occur on unmodified `origin/main`; this PR leaves that
  manifest unchanged.

## Remaining user steps and limits

New installations containing this hook need no auto-update setup or model
instruction. The hook runs at session start, using Python 3 or Node, and is a
no-op when already enabled. Failures never fail the session; missing runtimes
skip silently. A later startup retries a failed write. Global/managed update
restrictions and disabled hooks still take precedence in Claude Code.

Already-stale installations **must first receive this release**. A hook cannot
bootstrap itself into an older installed plugin. Those users need the two
manual update commands above and a new session once; a release announcement
should make this explicit. The manual `/plugin` auto-update toggle remains a
fallback. Codex's marketplace upgrade workflow is unchanged.
