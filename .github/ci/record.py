"""Fast post-build hook: root completed outputs for an asynchronous uploader."""

import os
from pathlib import Path
import sys


def record(directory, paths):
    for value in paths:
        path = Path(value)
        if path.parent != Path("/nix/store") or value.endswith(".drv"):
            raise ValueError("Expected a completed store output")
        root = directory / path.name
        try:
            root.symlink_to(path)
        except FileExistsError:
            if os.readlink(root) != value:
                raise ValueError("Conflicting output root")


if __name__ == "__main__":
    # Cache trouble must not cause Nix's synchronous hook to stop compilation.
    try:
        record(Path(sys.argv[1]), os.environ.get("OUT_PATHS", "").split())
    except Exception as error:
        print(f"::warning::Could not queue cache outputs: {error}", file=sys.stderr)
