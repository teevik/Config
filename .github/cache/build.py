"""Run a CI command while retaining completed builds, even if the command fails."""

import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import threading
import time
import uuid

from publish import publish_dependencies

GCROOTS = Path("/nix/var/nix/gcroots")


def pending_paths(directory, published):
    return sorted({os.readlink(path) for path in directory.iterdir() if path.is_symlink()} - published)


def upload_loop(directory, group, generation, stop, errors, interval=60):
    published = set()
    verified = set()
    while True:
        finishing = stop.wait(interval)
        try:
            paths = pending_paths(directory, published)
            # Bound each request and allow retries to make progress after a
            # failure, without reuploading previously acknowledged batches.
            for offset in range(0, len(paths), 256):
                batch = paths[offset:offset + 256]
                publish_dependencies(group, generation, batch, verified=verified)
                published.update(batch)
            errors.clear()
        except Exception as error:
            errors[:] = [error]
            print(f"::warning::Dependency cache upload will retry: {error}", file=sys.stderr, flush=True)
        if finishing:
            return


def run(group, generation, command):
    roots = GCROOTS / f"config-ci-{uuid.uuid4().hex}"
    subprocess.run(["sudo", "install", "-d", "-m", "0755", "-o", str(os.getuid()),
                    "-g", str(os.getgid()), str(roots)], check=True)
    stop, errors = threading.Event(), []
    with tempfile.TemporaryDirectory(prefix="config-cache-hook-") as temporary:
        hook = Path(temporary) / "hook"
        hook.write_text("#!/bin/sh\nexec " + shlex.join([
            sys.executable, str(Path(__file__).with_name("record.py").resolve()), str(roots),
        ]) + "\n")
        hook.chmod(0o755)
        env = dict(os.environ)
        for name in ["NIX_CACHE_SSH_KEY", "NIX_CACHE_SIGNING_KEY",
                     "NIX_CACHE_SSH_KEY_FILE", "NIX_CACHE_SIGNING_KEY_FILE", "NIX_CACHE_VERIFIED_PATHS"]:
            env.pop(name, None)
        env["NIX_CONFIG"] = env.get("NIX_CONFIG", "") + f"\npost-build-hook = {hook}\n"
        worker = threading.Thread(target=upload_loop, args=(roots, group, generation, stop, errors))
        worker.start()
        started = time.monotonic()
        try:
            result = subprocess.run(command, env=env)
        finally:
            finished = time.monotonic()
            print(f"Build command finished after {finished - started:.1f}s; draining cache uploads", flush=True)
            stop.set()
            worker.join()
            print(f"Cache upload drain finished after {time.monotonic() - finished:.1f}s", flush=True)
            for root in roots.iterdir():
                root.unlink()
            # The directory is runner-owned, but its parent is root-owned.
            subprocess.run(["sudo", "rmdir", str(roots)], check=True)
    if errors:
        print(f"::error::Could not retain completed build dependencies: {errors[0]}", file=sys.stderr)
    return result.returncode or (1 if errors else 0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("group")
    parser.add_argument("generation")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("a build command is required")
    raise SystemExit(run(args.group, args.generation, command))
