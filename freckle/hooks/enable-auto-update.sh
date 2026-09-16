#!/bin/sh
# Claude syncs this user setting into its marketplace registry on startup.
[ -n "${CLAUDE_CONFIG_DIR:-}${HOME:-}" ] || exit 0
config=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$config" 2>/dev/null || exit 0
lock=$config/.freckle-auto-update.lock
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null || :' 0
trap 'exit 0' HUP INT TERM

if command -v python3 >/dev/null 2>&1; then
  python3 - "$config/settings.json" <<'PY'
import json, os, pathlib, sys, tempfile
p = pathlib.Path(sys.argv[1]).resolve()
tmp = None
try:
    data = json.loads(p.read_text()) if p.exists() else {}
    entry = data.setdefault("extraKnownMarketplaces", {}).setdefault("freckle-plugins", {})
    if entry.get("autoUpdate") is True:
        sys.exit(0)
    entry.setdefault("source", {"source": "github", "repo": "freckle-io/agent-plugins"})
    entry["autoUpdate"] = True
    fd, tmp = tempfile.mkstemp(dir=p.parent, prefix=".freckle-settings-")
    with os.fdopen(fd, "w") as f:
        os.fchmod(f.fileno(), p.stat().st_mode & 0o777 if p.exists() else 0o600)
        f.write(json.dumps(data, indent=2) + "\n")
    os.replace(tmp, p)
    tmp = None
    print("Freckle: enabled marketplace auto-update.")
except Exception:
    print("Freckle: could not enable marketplace auto-update; leaving settings unchanged.")
finally:
    if tmp is not None:
        os.unlink(tmp)
PY
elif command -v node >/dev/null 2>&1; then
  node - "$config/settings.json" <<'JS'
const fs = require('fs');
let p = process.argv[2], tmp;
const object = x => {
  if (!x || typeof x !== 'object' || Array.isArray(x)) throw Error('Expected object');
  return x;
};
try {
  if (fs.existsSync(p)) p = fs.realpathSync(p);
  const data = object(fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : {});
  if (!Object.hasOwn(data, 'extraKnownMarketplaces')) data.extraKnownMarketplaces = {};
  const marketplaces = object(data.extraKnownMarketplaces);
  if (!Object.hasOwn(marketplaces, 'freckle-plugins')) marketplaces['freckle-plugins'] = {};
  const entry = object(marketplaces['freckle-plugins']);
  if (entry.autoUpdate !== true) {
    if (!Object.hasOwn(entry, 'source')) entry.source = {source: 'github', repo: 'freckle-io/agent-plugins'};
    entry.autoUpdate = true;
    tmp = p + '.freckle-' + process.pid;
    fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + '\n', {flag: 'wx', mode: 0o600});
    if (fs.existsSync(p)) fs.chmodSync(tmp, fs.statSync(p).mode & 0o777);
    fs.renameSync(tmp, p);
    tmp = undefined;
    console.error('Freckle: enabled marketplace auto-update.');
  }
} catch (_) {
  console.error('Freckle: could not enable marketplace auto-update; leaving settings unchanged.');
} finally {
  if (tmp) { try { fs.unlinkSync(tmp); } catch (_) {} }
}
JS
fi >&2
exit 0
