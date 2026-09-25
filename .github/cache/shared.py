"""Build the dependencies at the boundary between shared and host-specific work."""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import subprocess


def derivations(document, store_dir="/nix/store"):
    # Nix 2.35 uses versioned JSON and store-relative paths. Keep support for
    # the previous format so a bootstrap Nix update cannot silently empty a plan.
    if "derivations" in document:
        if document.get("version") != 4:
            raise ValueError("Unsupported Nix derivation JSON version")
        result = {}
        for name, value in document["derivations"].items():
            edges = {}
            for dependency, edge in value["inputs"]["drvs"].items():
                if edge.get("dynamicOutputs"):
                    raise ValueError("Dynamic derivations are not supported by the shared build planner")
                edges[f"{store_dir}/{dependency}"] = edge["outputs"]
            result[f"{store_dir}/{name}"] = dict(value, inputDrvs=edges)
        return result
    return document


def inputs(drv):
    return drv["inputDrvs"]


def shared_dependencies(graph, roots):
    if len(roots) < 2:
        raise ValueError("At least two host roots are required")
    closures = []
    for root in roots:
        seen, pending = set(), [root]
        while pending:
            drv = pending.pop()
            if drv not in seen:
                seen.add(drv)
                pending.extend(inputs(graph[drv]))
        closures.append(seen)
    shared = set.intersection(*closures) - set(roots)
    selected = defaultdict(set)
    # Only select shared outputs directly consumed by host-specific work.
    # Selecting every transitive dependency would fetch old compilers and
    # build inputs even when the package they build is already cached.
    for drv in set.union(*closures) - shared:
        for dependency, outputs in inputs(graph[drv]).items():
            if dependency in shared:
                selected[dependency].update(outputs)
    return {drv: sorted(outputs) for drv, outputs in sorted(selected.items())}


def query(*installables, recursive=False):
    store_dir = subprocess.check_output(["nix", "eval", "--raw", "--expr", "builtins.storeDir"], text=True)
    return derivations(json.loads(subprocess.check_output([
        "nix", "derivation", "show", *(["--recursive"] if recursive else []), *installables,
    ], text=True)), store_dir)


def plan(directory, installables):
    roots = query(*installables)
    graph = query(*roots, recursive=True)
    selected = shared_dependencies(graph, list(roots))
    directory.mkdir(parents=True, exist_ok=True)
    targets = [drv + "^" + ",".join(outputs) for drv, outputs in selected.items()]
    (directory / "shared-installables").write_text("".join(target + "\n" for target in targets))
    (directory / "shared-plan.json").write_text(json.dumps(selected, indent=2) + "\n")
    print(f"Shared build: {len(selected)} dependency roots for {len(roots)} hosts", flush=True)
    for drv, outputs in selected.items():
        print(f"  {Path(drv).name[33:-4]} ({', '.join(outputs)})", flush=True)


def build(directory):
    manifest = (directory / "shared-installables").read_text()
    paths = set()
    if manifest.strip():
        result = json.loads(subprocess.check_output([
            "nix", "build", "--no-link", "--print-build-logs", "--json", "--stdin",
        ], input=manifest, text=True))
        for entry in result:
            paths.update(entry["outputs"].values())
    (directory / "shared-paths").write_text("".join(path + "\n" for path in sorted(paths)))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["plan", "build"])
    parser.add_argument("directory", type=Path)
    parser.add_argument("installables", nargs="*")
    args = parser.parse_args()
    if args.operation == "plan":
        plan(args.directory, args.installables)
    else:
        build(args.directory)
