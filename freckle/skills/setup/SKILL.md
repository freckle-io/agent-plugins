---
name: setup
description: Freckle setup — install and authenticate the `freckle` CLI, which is how the plugin talks to Freckle. Use when `freckle` is not found on PATH or the `freckle` found on PATH is the wrong version, `freckle auth status` fails, the CLI isn't signed in, or the user wants to configure Freckle. Signs the user in for new users.
allowed-tools: Bash, Read, Edit, Write
---

# Freckle setup

Skills reach Freckle through the **`freckle` CLI**. **`freckle auth`** runs a device flow once
and stores the credential on disk; the CLI re-reads it on every command, so `freckle auth status`
succeeding is the whole proof.

## 1. Check current state

Run this and read the printed **exit code and output**, not any status string:

```bash
freckle auth status; echo "exit_code=$?"
```

- **exit_code=0** and the output shows a signed-in identity → the CLI is authenticated.
  Also confirm it isn't an old install shadowing the bundled launcher, which an
  auth check alone can't tell you — compare the resolved version against the
  release this plugin pins in `bin/cli-version` (two levels up from this skill's
  directory):

  ```bash
  # Prints e.g. `freckle v1.0.0`; compare the semver part.
  freckle --version
  # The pin is a full release tag like cli-v1.0.0-r299-3b81ee5; extract its semver.
  sed -e 's/^cli-v//' -e 's/-r.*//' "<THIS_SKILL_DIR>/../../bin/cli-version"
  ```

  - **same version, or newer than the pin** → the CLI is current. Tell the user
    (name the signed-in identity) and stop.
  - **older than the pin** → an outdated `freckle` is shadowing the bundled
    launcher. Do step 2 to put the launcher ahead of it on PATH, then re-run
    this check.

- **`freckle: command not found`** (or exit 127) → the CLI isn't on your PATH.
  Route by platform:
  - **Claude Code**: if the plugin was just installed in this session, this is expected —
    Claude Code only adds a newly installed plugin's `bin/` to PATH starting with the
    _next_ session. Don't install a forwarder for this: resolve the bundled launcher's
    absolute path once and invoke that directly for the rest of this session instead of
    waiting on a restart —

    ```bash
    launcher="$(sh -c 'ls -1dt "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/*/freckle/*/bin/freckle 2>/dev/null | head -n1')"
    [ -x "$launcher" ] || { echo "could not locate the bundled freckle launcher; reinstall the plugin"; exit 1; }
    "$launcher" auth status; echo "exit_code=$?"
    ```

    Use this same resolved path in place of bare `freckle` for every remaining command in
    this skill (step 3's `freckle auth` included) — but re-run the `ls -1dt` one-liner
    fresh immediately before each one rather than reusing `$launcher` across separate tool
    calls: each Bash call starts a new shell, so a variable set in one call is gone in
    the next. Bare `freckle` starts working again on its own once the agent is next
    restarted, so no restart is needed just for PATH. Only fall back to step 2's
    forwarder if the launcher can't be located at all (e.g. the plugin cache is gone),
    if another `freckle` install is shadowing the bundled one after a restart, or if
    bare `freckle` is still not found after a restart — that last case means the
    next-session auto-PATH isn't happening, so this is no longer a one-restart hiccup
    the launcher path can paper over.

  - **Codex**: go straight to step 2, then step 3 — Codex does not add a plugin's
    `bin/` to PATH automatically, so restarting alone won't fix this.

- **Any other nonzero exit** with output saying the CLI isn't authenticated → the CLI
  works but isn't signed in. Skip to step 3.
- **Network errors** → check the network and any `HTTP_API_ORIGIN` override; do not
  restart the sign-in flow.

## 2. Put `freckle` on your PATH (if it was "command not found" or is an outdated version)

The plugin bundles the CLI launcher at `bin/freckle` in the plugin root; it downloads
and checksum-verifies the real binary on first use. The launcher is version-stable
(it reads its neighbor `bin/cli-version` and fetches that release), so the forwarder
just needs to point at the newest launcher on disk.

Install a small forwarder onto your PATH (in `~/.local/bin`) that resolves the
newest bundled launcher **at runtime** rather than baking in one absolute path.
This is what lets it survive plugin updates (which install a new version directory)
and work no matter which agent (Claude Code / Codex) installed the plugin. It picks
the most-recently-modified launcher; if one agent's cache lags behind another's, the
freshest install wins — every launcher is self-contained, so it still runs a valid
checksum-verified CLI.

First confirm a launcher actually exists where the forwarder will look — this is
the same resolution the forwarder performs, run once now so a missing plugin
cache fails loudly here instead of as a confusing 127 later (run it through `sh`
so unmatched globs stay harmless even if your shell is zsh):

```bash
sh -c 'ls -1dt \
  "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/*/freckle/*/bin/freckle \
  "${CODEX_HOME:-$HOME/.codex}"/plugins/cache/*/freckle/*/bin/freckle \
  2>/dev/null | head -n1'
```

If this prints nothing, **stop** — no bundled launcher exists in any known plugin
cache, so the forwarder below would have nothing to exec. Tell the user to
reinstall the Freckle plugin, then re-run this skill. (If you read this SKILL.md
from a plugin root outside these caches, report that path to the user — the
plugin is installed somewhere this forwarder doesn't search.)

If it printed a path, install the forwarder (keep its search list in sync with
the pre-flight above and with step 1's Claude Code one-liner):

```bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/freckle" <<'EOF'
#!/bin/sh
# Resolve the newest bundled freckle launcher at runtime so this forwarder
# survives plugin version bumps and works whichever agent (Claude Code / Codex)
# installed it. CLAUDE_CONFIG_DIR and CODEX_HOME relocate those agents' state
# roots (and with them the plugin cache), so honor them when set — they expand
# here at runtime, from the invoking process's environment.
launcher="$(ls -1dt \
  "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/*/freckle/*/bin/freckle \
  "${CODEX_HOME:-$HOME/.codex}"/plugins/cache/*/freckle/*/bin/freckle \
  2>/dev/null | head -n1)"
if [ -z "$launcher" ] || [ ! -x "$launcher" ]; then
  printf 'Error: %s\n' 'freckle: no bundled launcher found (reinstall the Freckle plugin)' >&2
  exit 127
fi
exec "$launcher" "$@"
EOF
chmod +x "$HOME/.local/bin/freckle"
```

Then make sure `~/.local/bin` is on PATH (most shells already have it):

```bash
case ":$PATH:" in *":$HOME/.local/bin:"*) echo "on PATH" ;; *) echo "not on PATH" ;; esac
```

If it prints `not on PATH`, add `export PATH="$HOME/.local/bin:$PATH"` to the
user's shell profile (`~/.zshrc` or `~/.bashrc`) and use the absolute path
`"$HOME/.local/bin/freckle"` for the rest of this session.

Re-run the step 1 check before continuing.

> **Alternative — full install.** The standalone installer
> `sh -c "$(curl -fsSL https://install.freckle.io)"` installs the CLI directly to
> `~/.local/bin` with self-update enabled and also sets up agent skills outside
> this plugin. Use it when the user wants Freckle available outside plugin-managed
> agents; the plugin works with either.

## 3. Sign in

`freckle auth` is a device flow you run on the user's behalf. It opens the approval
page in the user's browser, prints a short one-time user code, and waits up to 15
minutes for approval. The credential lands directly in the CLI's local config; nothing
sensitive crosses the terminal or the conversation, and the user code itself is not a
secret — show it to the user so they can match it in the browser.

```bash
freckle auth
```

While the command waits, tell the user to approve the request in the opened browser
tab — signing in or creating an account there first is part of the same flow, and if
no browser opened, the printed URL gets them there. The command exits 0 once approved;
confirm with `freckle auth status`.

When device authorization is unavailable or there is no browser (headless or remote
shells), the user creates a token at https://next.freckle.io/cli-auth and you run:

```bash
freckle auth --token <frk_token>
```

Auth also resolves from `FRECKLE_CLI_TOKEN`.

## 4. Done

Re-run the step 1 check to confirm, tell the user who is signed in, and continue with
whatever task brought you here — the `freckle` skill routes all Freckle work.
