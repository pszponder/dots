"""Exercise COPR platform gates without changing host packages."""
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class CoprTests(unittest.TestCase):
    def test_fedora_only(self):
        source = (REPO / 'scripts/bootstrap/setup_copr.sh').read_text()
        with tempfile.TemporaryDirectory() as directory:
            release = Path(directory) / 'os-release'
            source = source.replace('/etc/os-release', str(release))
            source = source.rsplit('main "$@"', 1)[0]
            harness = source + '''
uname() { echo Linux; }
as_root() { printf 'run: %s\\n' "$*"; }
main
'''
            for distro, expected in [
                ('ubuntu', []),
                ('debian', []),
                ('arch', []),
                ('rhel', []),
                ('fedora', ['dnf copr enable -y scottames/ghostty']),
            ]:
                with self.subTest(distro=distro):
                    release.write_text(f'ID={distro}\n')
                    result = subprocess.run(
                        ['sh', '-c', harness], capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    calls = [line.removeprefix('run: ') for line in result.stdout.splitlines()
                             if line.startswith('run: ')]
                    self.assertEqual(calls, expected)
