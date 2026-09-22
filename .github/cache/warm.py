"""Copy existing build closures to a private cache without evaluating or building."""

import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess


def query(*args, input=None):
    return subprocess.check_output(args, input=input, text=True).strip()


def existing_build_paths(roots):
    """Include build-only outputs, even when absent from the runtime closure."""
    paths = set()
    for root in roots:
        root = Path(root).resolve(strict=True)
        if root.parent != Path("/nix/store"):
            raise ValueError(f"Expected a Nix store root, got {root}")
        paths.add(str(root))
        if root.suffix != ".drv":
            deriver = query("nix-store", "--query", "--deriver", str(root))
            if deriver != "unknown-deriver" and Path(deriver).is_file():
                paths.add(deriver)
    # Unlike copying just a system output, this follows the derivation graph
    # and includes the already-realized Rust crate outputs and bootstrap tools.
    # Missing outputs are omitted; no evaluation or realization takes place.
    return sorted(set(query(
        "nix-store", "--query", "--requisites", "--include-outputs", *sorted(paths),
    ).splitlines()))


def path_summary(paths):
    info = json.loads(query("nix", "path-info", "--json", "--json-format", "1", "--stdin",
                            input="\n".join(paths) + "\n"))
    return {
        "paths": len(paths),
        "derivations": sum(path.endswith(".drv") for path in paths),
        "upload_paths": sum(not path.endswith(".drv") for path in paths),
        "nar_bytes": sum(item["narSize"] for item in info.values()),
    }


def copy_paths(paths, destination, identity):
    # CI evaluates its own derivations. Upload their existing outputs and
    # sources; querying upstream caches for thousands of .drv files adds no
    # useful substitute hits. nix copy still includes all runtime references.
    paths = [path for path in paths if not path.endswith(".drv")]
    env = os.environ.copy()
    if destination == "ssh-ng://eu.nixbuild.net":
        if not identity.is_file():
            raise ValueError(f"Missing registered SSH identity: {identity}")
        known_hosts = Path(__file__).with_name("nixbuild-known-hosts").resolve()
        env["NIX_SSHOPTS"] = shlex.join([
            "-i", str(identity), "-o", "IdentitiesOnly=yes",
            "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
            "-o", f"UserKnownHostsFile={known_hosts}",
            "-o", "ConnectTimeout=15", "-o", "ServerAliveInterval=60",
        ])
    # Destination substitution avoids uploading packages already available
    # from its upstream caches. Explicit paths and nix copy never build.
    subprocess.run([
        "nix", "copy", "--to", destination, "--substitute-on-destination", "--stdin",
    ], input="\n".join(paths) + "\n", text=True, env=env, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("roots", nargs="+", help="Existing store outputs, .drv files or result symlinks")
    parser.add_argument("--store", default="ssh-ng://eu.nixbuild.net")
    parser.add_argument("--identity", type=Path, default=Path.home() / ".ssh/id_ed25519_nixbuild")
    parser.add_argument("--manifest", type=Path, help="Write the selected paths for inspection")
    parser.add_argument("--upload", action="store_true", help="Copy paths; otherwise only show the local inventory")
    args = parser.parse_args()
    paths = existing_build_paths(args.roots)
    if args.manifest:
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.write_text("\n".join(paths) + "\n")
    print(json.dumps(path_summary(paths), indent=2), flush=True)
    if args.upload:
        copy_paths(paths, args.store, args.identity.expanduser().resolve())
        print(f"Copied {sum(not path.endswith('.drv') for path in paths)} existing paths "
              f"to {args.store}; no builds requested.")


if __name__ == "__main__":
    main()
