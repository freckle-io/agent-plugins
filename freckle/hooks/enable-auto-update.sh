#!/bin/sh
# The setting itself is the marker: subsequent sessions do not rewrite it.
# Claude reconciles this user setting into plugins/known_marketplaces.json.
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
  config_dir=$CLAUDE_CONFIG_DIR
elif [ -n "${HOME:-}" ]; then
  config_dir=$HOME/.claude
else
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  runtime=python3
elif command -v node >/dev/null 2>&1; then
  runtime=node
else
  exit 0
fi

# Serialize our own concurrent SessionStart hooks; never block a session.
mkdir -p "$config_dir" 2>/dev/null || exit 0
lock=$config_dir/.freckle-auto-update.lock
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null || :' 0
trap 'exit 0' HUP INT TERM

if [ "$runtime" = python3 ]; then
  python3 - "$config_dir/settings.json" <<'PY' >&2
import json
import os
import stat
import sys
import tempfile

temporary = None
try:
    path = os.path.realpath(sys.argv[1])
    try:
        with open(path, "rb") as f:
            before = f.read()
    except FileNotFoundError:
        before = None
    data = json.loads(before) if before is not None else {}
    marketplaces = data.setdefault("extraKnownMarketplaces", {})
    entry = marketplaces.setdefault("freckle-plugins", {})
    if entry.get("autoUpdate") is True:
        sys.exit(0)
    entry.setdefault("source", {"source": "github", "repo": "freckle-io/agent-plugins"})
    entry["autoUpdate"] = True
    fd, temporary = tempfile.mkstemp(prefix=".freckle-settings-", dir=os.path.dirname(path))
    with os.fdopen(fd, "w") as f:
        os.fchmod(f.fileno(), stat.S_IMODE(os.stat(path).st_mode) if before is not None else 0o600)
        f.write(json.dumps(data, indent=2) + "\n")
    # Avoid overwriting edits made while we were preparing the replacement.
    try:
        with open(path, "rb") as f:
            current = f.read()
    except FileNotFoundError:
        current = None
    if current == before:
        os.replace(temporary, path)
        temporary = None
        print("Freckle: enabled marketplace auto-update.", file=sys.stderr)
except Exception:
    print("Freckle: could not enable marketplace auto-update; leaving settings unchanged.", file=sys.stderr)
finally:
    if temporary is not None:
        os.unlink(temporary)
PY
else
  node - "$config_dir/settings.json" <<'JS' >&2
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
let temporary;
try {
  let target = process.argv[2];
  try { target = fs.realpathSync(target); } catch (e) { if (e.code !== 'ENOENT') throw e; }
  const read = () => {
    try { return fs.readFileSync(target, 'utf8'); }
    catch (e) { if (e.code === 'ENOENT') return null; throw e; }
  };
  const object = value => {
    if (!value || typeof value !== 'object' || Array.isArray(value)) throw Error('Expected object');
    return value;
  };
  const before = read();
  const data = object(before === null ? {} : JSON.parse(before));
  if (!Object.hasOwn(data, 'extraKnownMarketplaces')) data.extraKnownMarketplaces = {};
  const marketplaces = object(data.extraKnownMarketplaces);
  if (!Object.hasOwn(marketplaces, 'freckle-plugins')) marketplaces['freckle-plugins'] = {};
  const entry = object(marketplaces['freckle-plugins']);
  if (entry.autoUpdate !== true) {
    if (!Object.hasOwn(entry, 'source')) entry.source = {source: 'github', repo: 'freckle-io/agent-plugins'};
    entry.autoUpdate = true;
    temporary = path.join(path.dirname(target), '.freckle-settings-' + crypto.randomBytes(12).toString('hex'));
    fs.writeFileSync(temporary, JSON.stringify(data, null, 2) + '\n', {flag: 'wx', mode: 0o600});
    if (before !== null) fs.chmodSync(temporary, fs.statSync(target).mode & 0o777);
    if (read() === before) {
      fs.renameSync(temporary, target);
      temporary = undefined;
      console.error('Freckle: enabled marketplace auto-update.');
    }
  }
} catch (_) {
  console.error('Freckle: could not enable marketplace auto-update; leaving settings unchanged.');
} finally {
  if (temporary) { try { fs.unlinkSync(temporary); } catch (_) {} }
}
JS
fi
exit 0
