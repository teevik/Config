"""Expose every Nixpkgs node as a root input for Flake Checker's root-only scan."""

import json
from pathlib import Path
import sys


def project(lock):
    nodes = lock["nodes"]
    selected = {
        name: name for name, node in nodes.items()
        if node.get("original", {}).get("repo", "").lower() == "nixpkgs"
        or name == "nixpkgs" or name.startswith("nixpkgs_")
    }
    if not selected:
        raise ValueError("No Nixpkgs inputs found")
    root = "security-check-root"
    if root in nodes:
        raise ValueError("Reserved projection node already exists")
    return dict(lock, root=root, nodes={**nodes, root: {"inputs": selected}}), ",".join(sorted(selected))


if __name__ == "__main__":
    projected, keys = project(json.loads(Path(sys.argv[1]).read_text()))
    Path(sys.argv[2]).write_text(json.dumps(projected))
    print(keys)
