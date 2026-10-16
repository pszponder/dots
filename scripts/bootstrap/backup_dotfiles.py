"""Move dotfile conflicts aside before mise replaces them."""

import json
import os
from pathlib import Path
import shutil
import subprocess


def expand_path(value):
    return Path(os.path.abspath(os.path.expanduser(value)))


def conflicts(files):
    # Explicit template/copy entries override files discovered by symlink-each.
    explicit_targets = {
        expand_path(entry["target"])
        for entry in files if entry["mode"] != "symlink-each"
    }
    explicit_sources = {
        expand_path(entry["origin"]["source"]).resolve()
        for entry in files
        if entry["mode"] != "symlink-each" and entry.get("origin", {}).get("source")
    }

    def walk(source, target):
        if source in explicit_sources or target in explicit_targets:
            return
        if target.is_symlink() and target.resolve() == source.resolve():
            return
        if source.is_dir() and not source.is_symlink():
            if target.is_symlink() or (target.exists() and not target.is_dir()):
                yield target
            else:
                for child in sorted(source.iterdir()):
                    yield from walk(child, target / child.name)
        elif os.path.lexists(target):
            if not (target.is_symlink() and target.resolve() == source.resolve()):
                yield target

    for entry in files:
        if entry["mode"] == "symlink-each":
            yield from walk(expand_path(entry["origin"]["source"]).resolve(), expand_path(entry["target"]))
        elif entry["mode"] not in ("permissions", "track", "track-local") and entry["state"] in ("differs", "would_remove"):
            target = expand_path(entry["target"])
            if os.path.lexists(target):
                yield target


def main():
    result = subprocess.run(
        ["mise", "dot", "status", "--json"], check=True, text=True, stdout=subprocess.PIPE,
    )
    home = Path.home().absolute()
    targets = sorted(set(conflicts(json.loads(result.stdout)["files"])), key=lambda p: (len(p.parts), str(p)))
    # Validate every target before moving anything.
    for target in targets:
        if target == home or not target.is_relative_to(home):
            raise SystemExit(f"Refusing to back up a target outside the home directory: {target}")
    moved = []
    for target in targets:
        if any(target.is_relative_to(parent) for parent in moved):
            continue
        destination = target.with_name(target.name + ".bak")
        index = 0
        while os.path.lexists(destination):
            index += 1
            destination = target.with_name(target.name + f".bak.{index}")
        shutil.move(str(target), str(destination))
        moved.append(target)
        print(f"Backed up {target} to {destination}", flush=True)


if __name__ == "__main__":
    main()
