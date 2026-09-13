"""Present the production workspace to cargo-nix-plugin's lockfile resolver."""

import sys
import tomllib
from pathlib import Path

import tomli_w


root = Path(sys.argv[1])
manifest_path = root / "Cargo.toml"
workspace = tomllib.loads(manifest_path.read_text())
roots = ["crates/zed", "crates/cli", "crates/gpui_platform"]
# The resolver discovers ordinary path edges, but not [patch] path entries.
roots += [
    patch["path"]
    for patches in workspace.get("patch", {}).values()
    for patch in patches.values()
    if "path" in patch
]
pending = list(roots)
seen = set()
names = set()
while pending:
    relative = pending.pop()
    directory = (root / relative).resolve()
    if directory in seen:
        continue
    assert directory.is_relative_to(root), directory
    seen.add(directory)
    path = directory / "Cargo.toml"
    manifest = tomllib.loads(path.read_text())
    names.add(manifest["package"]["name"])
    tables = [manifest, *manifest.get("target", {}).values()]
    for table in tables:
        table.pop("dev-dependencies", None)
        for kind in ("dependencies", "build-dependencies"):
            for name, dependency in table.get(kind, {}).items():
                if not isinstance(dependency, dict):
                    continue
                base = directory
                if dependency.get("workspace"):
                    dependency = workspace["workspace"]["dependencies"][name]
                    base = root
                if isinstance(dependency, dict) and "path" in dependency:
                    pending.append(str((base / dependency["path"]).relative_to(root)))
    path.write_text(tomli_w.dumps(manifest))

workspace["workspace"]["members"] = roots
workspace["workspace"]["default-members"] = ["crates/zed", "crates/cli"]
workspace["workspace"].pop("exclude", None)
manifest_path.write_text(tomli_w.dumps(workspace))
# The original lock also contains local tools/tests outside this production
# closure. Their source-less entries otherwise fail the resolver's path lookup.
lock_path = root / "Cargo.lock"
lock = tomllib.loads(lock_path.read_text())
lock["package"] = [
    package for package in lock["package"]
    if "source" in package or package["name"] in names
]
lock_path.write_text(tomli_w.dumps(lock))
