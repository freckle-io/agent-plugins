#!/usr/bin/env python3
"""Build git-free hosted marketplaces for Claude Code and Codex.

Claude Code: zips every plugin listed in .claude-plugin/marketplace.json with
a relative-path source, and writes a marketplace.json whose entries use
`archive` sources (HTTPS zip + sha256). Users add it by URL, so installing
and updating never runs git.

Codex: has no URL marketplace source, so this also zips the Codex marketplace
(.agents/plugins/marketplace.json plus its local plugins) for users to
download with curl, unzip and add as a local path.

Usage: build-hosted-marketplace.py <base-url> <out-dir> <revision>
  base-url  public HTTPS origin the out-dir is served from
  revision  short commit sha, keeps each archive path immutable
"""
import hashlib
import json
import os
import sys
import zipfile
from pathlib import Path

# Fixed timestamp so identical trees produce identical zips (and sha256).
EPOCH = (1980, 1, 1, 0, 0, 0)
SKIP = {".DS_Store"}


def zip_tree(base: Path, roots: list[Path], prefix: str, dest: Path) -> str:
    files = sorted(
        p for root in roots for p in ([root] if root.is_file() else root.rglob("*"))
        if p.is_file() and p.name not in SKIP
    )
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in files:
            info = zipfile.ZipInfo(f"{prefix}/{path.relative_to(base).as_posix()}", EPOCH)
            mode = 0o755 if os.access(path, os.X_OK) else 0o644
            info.external_attr = (0o100000 | mode) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            zf.writestr(info, path.read_bytes())
    return hashlib.sha256(dest.read_bytes()).hexdigest()


def main() -> None:
    base_url, out_dir, revision = sys.argv[1].rstrip("/"), Path(sys.argv[2]), sys.argv[3]
    if not base_url.startswith("https://"):
        sys.exit("base-url must be https:// (archive sources require it)")
    root = Path(__file__).resolve().parent.parent
    marketplace = json.loads((root / ".claude-plugin/marketplace.json").read_text())

    for entry in marketplace["plugins"]:
        source = entry["source"]
        if not isinstance(source, str):
            continue  # already a remote source; publish as-is
        plugin_dir = (root / source).resolve()
        manifest = json.loads((plugin_dir / ".claude-plugin/plugin.json").read_text())
        version = manifest.get("version", "0.0.0")
        rel = f"plugins/{entry['name']}/{version}-{revision}/{entry['name']}.zip"
        sha256 = zip_tree(plugin_dir, [plugin_dir], plugin_dir.name, out_dir / rel)
        # Version stays in plugin.json only; a changed version is what makes
        # users (and auto-update) pick up the new archive.
        entry["source"] = {"source": "archive", "url": f"{base_url}/{rel}", "sha256": sha256}
        print(f"{entry['name']} {version}: {rel} sha256={sha256}")

    (out_dir / "marketplace.json").write_text(json.dumps(marketplace, indent=2) + "\n")

    codex_manifest = root / ".agents/plugins/marketplace.json"
    codex = json.loads(codex_manifest.read_text())
    roots = [codex_manifest] + [
        (root / e["source"]["path"]).resolve()
        for e in codex["plugins"]
        if isinstance(e["source"], dict) and e["source"].get("source") == "local"
    ]
    # Stable name: users re-download the same URL to upgrade (Codex has no
    # plugin auto-update). The .sha256 lets the install prompt verify it.
    sha256 = zip_tree(root, roots, codex["name"], out_dir / "codex" / f"{codex['name']}.zip")
    (out_dir / "codex" / f"{codex['name']}.zip.sha256").write_text(sha256 + "\n")
    print(f"codex {codex['name']}: codex/{codex['name']}.zip sha256={sha256}")


if __name__ == "__main__":
    main()
