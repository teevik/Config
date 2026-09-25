"""Validate the native runner's artifact before copying into another job."""

import json
from pathlib import Path
import shutil
import stat
import sys


def install(root, artifact):
    allowed = sorted(set(json.loads((root / "packages/update-packages.json").read_text()).values()))
    manifest = artifact / "files.txt"
    if manifest.is_symlink() or not manifest.is_file():
        raise ValueError("Invalid update manifest")
    if manifest.read_text().splitlines() != allowed:
        raise ValueError("Update manifest differs from the trusted package catalog")
    sources = artifact / "sources"
    if sources.is_symlink() or not sources.is_dir():
        raise ValueError("Invalid update source directory")
    found = []
    for path in sources.rglob("*"):
        mode = path.lstat().st_mode
        if stat.S_ISDIR(mode):
            continue
        if not stat.S_ISREG(mode):
            raise ValueError("Update contains a symlink or special file")
        found.append(path.relative_to(sources).as_posix())
    if sorted(found) != allowed:
        raise ValueError("Update contains unexpected or missing files")
    for name in allowed:
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or ".git" in path.parts:
            raise ValueError("Unsafe update path")
        target = root / path
        if target.resolve() != root.resolve() / path:
            raise ValueError("Update target crosses a symlink")
    # Validate the entire artifact before changing the checkout. Do not copy
    # permissions, symlinks, .git metadata, scripts or a caller-supplied catalog.
    for name in allowed:
        shutil.copyfile(sources / name, root / name)


if __name__ == "__main__":
    install(Path.cwd(), Path(sys.argv[1]))
