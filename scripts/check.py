"""Validate repository configuration without applying it."""
from pathlib import Path
import shutil
import subprocess
import tomllib


def main():
    root = Path(__file__).resolve().parents[1]
    for path in [*root.glob('mise*.toml'), *(root / 'dots').rglob('*.toml')]:
        if path.name.endswith('.local.toml'):
            continue
        with path.open('rb') as source:
            tomllib.load(source)

    shells = {root / 'install.sh': 'sh'}
    shells.update({path: 'bash' if 'bash' in path.read_text().splitlines()[0] else 'sh'
                   for path in (root / 'scripts').rglob('*.sh')})
    shells.update({path: 'bash' for path in (root / 'dots/.local/bin').iterdir()
                   if path.is_file() and 'bash' in path.read_text().splitlines()[0]})
    for name in ('.bashrc', '.bash_profile', '.profile', '.config/aliases',
                 '.config/shell/functions.sh'):
        shells[root / 'dots' / name] = 'bash'
    zsh_files = ['.zshenv', '.config/zsh/.zshrc', '.config/zsh/.zprofile']
    if shutil.which('zsh'):
        shells.update({root / 'dots' / name: 'zsh' for name in zsh_files})
    else:
        print('Skipping Zsh syntax checks: install zsh to include them (CI does).')
    for path, shell in sorted(shells.items()):
        subprocess.run([shell, '-n', str(path)], check=True)
    print('TOML and shell syntax checks passed.')


if __name__ == '__main__':
    main()
