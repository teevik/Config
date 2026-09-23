"""Copy existing local build dependencies to the private cache without building."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess

from publish import publish_dependencies


def existing_outputs(roots):
    paths = set()
    for root in roots:
        root = str(Path(root).resolve())
        if not root.endswith(".drv"):
            deriver = subprocess.check_output(
                ["nix-store", "--query", "--deriver", root], text=True,
            ).strip()
            if deriver != "unknown-deriver" and Path(deriver).exists():
                root = deriver
        paths.update(subprocess.check_output(
            ["nix-store", "--query", "--requisites", "--include-outputs", root], text=True,
        ).splitlines())
    # Querying requisites never realises missing outputs. Do not upload .drv
    # files: rooting them could retain more than the declared output budget.
    return sorted(path for path in paths if not path.endswith(".drv") and Path(path).exists())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("roots", nargs="+", help="Existing system/package store paths or derivations")
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--upload", action="store_true")
    args = parser.parse_args()
    paths = existing_outputs(args.roots)
    args.manifest.write_text("".join(path + "\n" for path in paths))
    info = json.loads(subprocess.check_output(
        ["nix", "path-info", "--json", "--stdin"], input=args.manifest.read_text(), text=True,
    ))
    entries = info.values() if isinstance(info, dict) else info
    size = sum(entry["narSize"] for entry in entries)
    print(f"Selected {len(paths)} existing outputs ({size / 1024**3:.1f} GiB); manifest: {args.manifest}", flush=True)
    if args.upload:
        generation = datetime.now(timezone.utc).strftime("desktop-%Y%m%dT%H%M%SZ")
        publish_dependencies("seed", generation, paths)
