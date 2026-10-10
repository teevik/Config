"""Write the nightly update pull request body and warn about failed updates.

Usage: pr-body.py OLD_LOCK NEW_LOCK ARTIFACT RUN_URL OUTPUT

Diffs the locked flake inputs, lists the updates recorded in the artifact's
failures.json, prints a workflow warning for each failure and writes the
Markdown body to OUTPUT.
"""

import json
from pathlib import Path
import re
import sys

INTRO = (
    "Automated flake input and package update. Desktop and zenbook were built and scanned, "
    "and nix flake check passed using these exact files. System closures and successful check "
    "outputs were retained and verified in the private homelab cache."
)


def revision(lock):
    rev = (lock or {}).get("rev")
    return "not present" if rev is None or rev is False else rev


def changed_inputs(old, new):
    """Return a Markdown table row for every node whose locked entry changed."""
    before, after = old.get("nodes") or {}, new.get("nodes") or {}
    rows = []
    for name in sorted(before.keys() | after.keys()):
        old_lock = (before.get(name) or {}).get("locked")
        new_lock = (after.get(name) or {}).get("locked")
        if old_lock != new_lock:
            rows.append(f"| `{name}` | `{revision(old_lock)}` | `{revision(new_lock)}` |")
    return rows


def warnings(failures):
    """Return one workflow warning per failure; errors are untrusted text."""
    lines = []
    for failure in failures:
        line = f"::warning title=Nightly update failed::{failure['label']}: {failure['error']}"
        lines.append(line.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A"))
    return lines


def failed_update(failure):
    """Fence the error with more backticks than any run inside it."""
    longest = max((len(run) for run in re.findall("`+", failure["error"])), default=0)
    fence = "`" * max(longest + 1, 3)
    return f"**{failure['label']}**\n\n{fence}text\n{failure['error']}\n{fence}"


def render(old, new, failures, run_url):
    rows = changed_inputs(old, new) or ["| _No locked inputs changed_ | — | — |"]
    lines = [
        INTRO,
        "",
        "Security scans are informational; see the per-host job summaries and encrypted security artifacts.",
        f"Run: {run_url}",
        "",
        "### Changed inputs",
        "",
        "| Input | Old revision | New revision |",
        "| --- | --- | --- |",
        *rows,
    ]
    if failures:
        lines += [
            "",
            "### Failed updates",
            "",
            "These updates failed and are not part of this pull request. Their files were left unchanged.",
            "",
            "\n\n".join(failed_update(failure) for failure in failures),
        ]
    return "\n".join(lines) + "\n"


def main(old_lock, new_lock, artifact, run_url, output):
    old = json.loads(Path(old_lock).read_text())
    new = json.loads(Path(new_lock).read_text())
    failures = json.loads((Path(artifact) / "failures.json").read_text())
    for line in warnings(failures):
        print(line)
    Path(output).write_text(render(old, new, failures, run_url))


if __name__ == "__main__":
    main(*sys.argv[1:])
