"""Validate the nightly update artifact before copying into the PR job."""

import json
from pathlib import Path
import shutil
import stat
import sys


def install(root, artifact):
    catalog = json.loads((root / "packages/update-packages.json").read_text())
    allowed = {"flake.lock", *catalog.values()}
    manifest = artifact / "files.txt"
    if manifest.is_symlink() or not manifest.is_file():
        raise ValueError("Invalid update manifest")
    # Failed package updates are left out, so any sorted, non-empty subset of
    # the trusted catalog is acceptable; failures.json reports the rest.
    files = manifest.read_text().splitlines()
    if not files or files != sorted(set(files)):
        raise ValueError("Update manifest is empty, unsorted or has duplicates")
    if not set(files) <= allowed:
        raise ValueError("Update manifest is not part of the trusted package catalog")
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
    if sorted(found) != files:
        raise ValueError("Update contains unexpected or missing files")
    for name in files:
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or ".git" in path.parts:
            raise ValueError("Unsafe update path")
        target = root / path
        if target.resolve() != root.resolve() / path:
            raise ValueError("Update target crosses a symlink")
    # Validate the entire artifact before changing the checkout. Do not copy
    # permissions, symlinks, .git metadata, scripts or a caller-supplied catalog.
    for name in files:
        shutil.copyfile(sources / name, root / name)


if __name__ == "__main__":
    install(Path.cwd(), Path(sys.argv[1]))
