"""Validate MCP plugin wiring, reference reachability, and absence of CLI runtime dependencies."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
plugin = root / 'freckle-mcp'
for kind in ('claude', 'codex'):
    manifest = json.loads((plugin / f'.{kind}-plugin/plugin.json').read_text())
    assert manifest['name'] == 'freckle-mcp'
    assert 'hooks' not in manifest
    assert (plugin / manifest['skills']).is_dir()
    config = json.loads((plugin / manifest['mcpServers']).read_text())
    server = config['mcpServers']['freckle']
    assert server['type'] == 'http' and server['url'].endswith('/mcp/full')
    assert 'command' not in server
for doc in (plugin / 'skills').rglob('*.md'):
    text = doc.read_text()
    assert not re.search(r'(?m)^\s*(?:\$\s*)?freckle\s|```(?:bash|shell)|command -v freckle|--org-id|--input-json|--search-file|--file', text), doc
    for target in re.findall(r'\]\(([^)]+)\)', text):
        if '://' in target or target.startswith('#'):
            continue
        assert (doc.parent / target.split('#')[0]).exists(), (doc, target)
assert not (plugin / 'bin').exists()
assert not (plugin / 'hooks').exists()
print('MCP plugin manifests, references, and runtime isolation validated')
