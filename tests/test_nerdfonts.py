"""Offline checks for native Arch fonts and portable installer guidance."""
from pathlib import Path
import os
import subprocess
import tempfile
import tomllib
import unittest

REPO = Path(__file__).resolve().parents[1]


class NerdFontTests(unittest.TestCase):
    def test_arch_packages_match_configured_families(self):
        packages = tomllib.loads((REPO / 'mise.workstation-arch.toml').read_text())['bootstrap']['packages']
        shared = tomllib.loads((REPO / 'mise.toml').read_text())['bootstrap'].get('packages', {})
        for name in ('ttf-cascadia-code-nerd', 'ttf-cascadia-mono-nerd', 'ttf-jetbrains-mono-nerd'):
            self.assertIn(f'pacman:{name}', packages)
            self.assertNotIn(f'pacman:{name}', shared)

    def test_arch_skips_downloads_and_other_platforms_offer_generic_guidance(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            release = root / 'os-release'
            source = (REPO / 'scripts/cli/nerdfonts_install.sh').read_text()
            source = source.replace('"$SCRIPT_DIR/../utils/utils_logging.sh"',
                                    f'"{REPO / "scripts/utils/utils_logging.sh"}"')
            source = source.replace('/etc/os-release', str(release))
            script = root / 'fonts.sh'
            script.write_text(source)
            uname = root / 'uname'
            uname.write_text('#!/bin/sh\nprintf "%s\\n" "$TEST_OS"\n')
            uname.chmod(0o755)
            curl = root / 'curl'
            curl.write_text('#!/bin/sh\ntouch "$DOWNLOAD_MARKER"\nexit 99\n')
            curl.chmod(0o755)
            marker = root / 'download'
            env = dict(os.environ, HOME=str(root), PATH=f'{root}:/usr/bin:/bin',
                       NERDFONTS_MANIFEST=str(root / 'missing-manifest'), DOWNLOAD_MARKER=str(marker))
            for platform, metadata, skip in (
                ('Linux', 'ID=arch\n', True),
                ('Linux', 'ID=manjaro\nID_LIKE=arch\n', True),
                ('Linux', 'ID=fedora\n', False),
                ('Linux', 'ID=debian\n', False),
                ('Darwin', 'ID=arch\n', False),
            ):
                with self.subTest(platform=platform, metadata=metadata):
                    release.write_text(metadata)
                    env['TEST_OS'] = platform
                    result = subprocess.run(['sh', str(script)], env=env, capture_output=True, text=True)
                    if skip:
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertIn('managed by pacman', result.stdout)
                    else:
                        self.assertNotEqual(result.returncode, 0)
                        self.assertIn('<your-profile>', result.stderr)
                        self.assertNotIn('workstation-ubuntu', result.stderr)
                    self.assertFalse(marker.exists())
