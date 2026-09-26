#!/usr/bin/env python3
"""Compare or install VS Code or Cursor extensions from their stowed list."""

import argparse
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("status", "install"), nargs="?", default="status")
    parser.add_argument("--editor", choices=("code", "cursor"), default="code")
    args = parser.parse_args()
    config = "Code" if args.editor == "code" else "Cursor"
    manifest = Path(__file__).resolve().parents[1] / f"dotfiles/.config/{config}/extensions.txt"
    wanted = set()
    for number, line in enumerate(manifest.read_text().splitlines(), 1):
        extension = line.partition("#")[0].strip().lower()
        if not extension:
            continue
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9-]*", extension):
            parser.error(f"{manifest}:{number}: invalid extension ID: {extension}")
        if extension in wanted:
            parser.error(f"{manifest}:{number}: duplicate extension ID: {extension}")
        wanted.add(extension)
    if not wanted:
        parser.error(f"{manifest}: extension list is empty")

    result = subprocess.run(
        [args.editor, "--list-extensions"], check=True, text=True, stdout=subprocess.PIPE
    )
    installed = set(result.stdout.lower().splitlines())
    missing = sorted(wanted - installed)
    extra = sorted(installed - wanted)
    print(f"{len(wanted)} listed; {len(installed)} installed.", flush=True)
    for label, extensions in (("Missing", missing), ("Installed but unlisted", extra)):
        print(f"{label}:", flush=True)
        print("\n".join(f"  {extension}" for extension in extensions) or "  (none)", flush=True)

    if args.action == "install" and missing:
        command = [args.editor]
        for extension in missing:
            command.extend(["--install-extension", extension])
        subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
