"""Settings safety and interpreter parity; no Claude account or network required."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'freckle/hooks/enable-auto-update.sh'


class AutoUpdateHookTest(unittest.TestCase):
    def test_settings_safety(self):
        for runtime in ('python3', 'node'):
            executable = shutil.which(runtime)
            if not executable:
                self.fail(f'{runtime} is required to test both interpreter paths')
            with self.subTest(runtime=runtime), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                binaries = root / 'bin'
                binaries.mkdir()
                for name in ('mkdir', 'rmdir'):
                    (binaries / name).symlink_to(shutil.which(name))
                (binaries / runtime).symlink_to(executable)
                config = root / 'custom config'
                env = {**os.environ, 'HOME': str(root), 'CLAUDE_CONFIG_DIR': str(config), 'PATH': str(binaries)}
                settings = config / 'settings.json'

                def run():
                    result = subprocess.run(['/bin/sh', str(HOOK)], env=env, capture_output=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout, b'')
                    return result

                run()
                self.assertTrue(json.loads(settings.read_text())['extraKnownMarketplaces']['freckle-plugins']['autoUpdate'])
                self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
                self.assertFalse((root / '.claude').exists())
                previous = (settings.read_bytes(), settings.stat().st_mtime_ns)
                self.assertEqual(run().stderr, b'')
                self.assertEqual(previous, (settings.read_bytes(), settings.stat().st_mtime_ns))

                data = {'permissions': {'allow': ['Bash(freckle *)']}, 'extraKnownMarketplaces': {
                    'other': {'source': {'source': 'directory', 'path': '/example'}},
                    'freckle-plugins': {'source': {'source': 'github', 'repo': 'freckle-io/agent-plugins', 'ref': 'main'}, 'autoUpdate': False, 'custom': 'keep'}}}
                settings.write_text(json.dumps(data))
                settings.chmod(0o640)
                run()
                data['extraKnownMarketplaces']['freckle-plugins']['autoUpdate'] = True
                self.assertEqual(json.loads(settings.read_text()), data)
                self.assertEqual(settings.stat().st_mode & 0o777, 0o640)

                for broken in ('{', '[]', 'null', '{"extraKnownMarketplaces":null}', '{"extraKnownMarketplaces":{"freckle-plugins":[]}}'):
                    settings.write_text(broken)
                    run()
                    self.assertEqual(settings.read_text(), broken)

                settings.unlink()
                real = root / 'linked-settings.json'
                real.write_text('{}')
                settings.symlink_to(real)
                run()
                self.assertTrue(settings.is_symlink())
                self.assertTrue(json.loads(real.read_text())['extraKnownMarketplaces']['freckle-plugins']['autoUpdate'])
                self.assertEqual(list(config.glob('.freckle-*')), [])

                # A concurrent hook holds the lock: leave settings alone and retry next session.
                real.write_text('{}')
                lock = config / '.freckle-auto-update.lock'
                lock.mkdir()
                self.assertEqual(run().stderr, b'')
                self.assertEqual(real.read_text(), '{}')
                lock.rmdir()
                (binaries / runtime).unlink()
                self.assertEqual(run().stderr, b'')
                self.assertEqual(real.read_text(), '{}')

    def test_home_default(self):
        with tempfile.TemporaryDirectory() as tmp:
            env = {**os.environ, 'HOME': tmp}
            env.pop('CLAUDE_CONFIG_DIR', None)
            result = subprocess.run(['/bin/sh', str(HOOK)], env=env, capture_output=True)
            self.assertEqual(result.returncode, 0)
            self.assertTrue((Path(tmp) / '.claude/settings.json').exists())


if __name__ == '__main__':
    unittest.main()
