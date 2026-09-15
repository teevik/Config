"""Offline differential tests against the real Nix lock-file writer.

Run with: python3 tests/update-inputs.py
Requires Git, Determinate Nix with parallel-eval enabled, and Nu on PATH.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


SCRIPT = Path(__file__).resolve().parents[1] / "packages/update-inputs.nu"


def run(*args, cwd, check=True, env=None):
    result = subprocess.run(
        args, cwd=cwd, env=env, text=True, capture_output=True, timeout=120
    )
    if check and result.returncode:
        raise AssertionError(f"{args}:\n{result.stdout}\n{result.stderr}")
    return result


def write_flake(repo, inputs):
    declarations = "\n".join(f"{key} = {value};" for key, value in inputs.items())
    (repo / "flake.nix").write_text(
        "{ inputs = {" + declarations + '}; outputs = _: throw "must stay lazy"; }\n'
    )


def commit(repo):
    run("git", "add", ".", cwd=repo)
    run(
        "git", "-c", "user.name=Fixture", "-c", "user.email=fixture@localhost",
        "-c", "commit.gpgsign=false", "commit", "-qm", "fixture", cwd=repo,
    )
    return run("git", "rev-parse", "HEAD", cwd=repo).stdout.strip()


def repository(base, name, inputs=None):
    repo = base / name
    repo.mkdir()
    run("git", "init", "-q", "-b", "main", "--template=", cwd=repo)
    write_flake(repo, inputs or {})
    commit(repo)
    return repo


def url(repo, suffix=""):
    return f"git+{repo.as_uri()}?ref=main{suffix}"


def compare(root, *args):
    expected_path = root / "expected.lock"
    run("nix", "flake", "update", *args, "--output-lock-file", str(expected_path), cwd=root)
    expected = json.loads(expected_path.read_text())
    expected_path.unlink()
    run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), *args, cwd=root)
    actual = json.loads((root / "flake.lock").read_text())
    assert actual == expected, f"Lock differs from native Nix: {root.name}, {args}"
    assert not list(root.glob(".flake-update.*"))
    return actual


def main():
    with tempfile.TemporaryDirectory(prefix="flake update tests ") as temporary:
        base = Path(temporary)
        leaf = repository(base, "leaf")
        old = run("git", "rev-parse", "HEAD", cwd=leaf).stdout.strip()
        nested = repository(base, "nested", {"dep.url": json.dumps(url(leaf))})
        run("nix", "flake", "lock", cwd=nested)
        commit(nested)
        subdir = repository(base, "subdir")
        (subdir / "sub").mkdir()
        write_flake(subdir / "sub", {})
        commit(subdir)
        inputs = {
            "a.url": json.dumps(url(leaf)),
            "alias.url": json.dumps(url(leaf)),
            "pinned.url": json.dumps(url(leaf, f"&rev={old}")),
            "nested.url": json.dumps(url(nested)),
            "follow.follows": '"a"',
            "raw.url": json.dumps(url(leaf)),
            "raw.flake": "false",
            "subdir.url": json.dumps(url(subdir, "&dir=sub")),
        }
        root = repository(base, "root", inputs)
        compare(root)
        (root / "flake.lock").chmod(0o640)
        (leaf / "new.txt").write_text("new revision")
        commit(leaf)
        graph = compare(root)
        assert (root / "flake.lock").stat().st_mode & 0o777 == 0o640
        nodes = graph["nodes"]
        roots = nodes[graph["root"]]["inputs"]
        assert nodes[roots["a"]]["locked"]["rev"] != old
        assert nodes[roots["pinned"]]["locked"]["rev"] == old
        assert nodes[nodes[roots["nested"]]["inputs"]["dep"]]["locked"]["rev"] == old
        compare(root)
        inputs["nested.inputs.dep.follows"] = '"a"'
        write_flake(root, inputs)
        compare(root)
        del inputs["nested.inputs.dep.follows"]
        print("PASS: missing lock, fresh roots, shared nodes, pinned nested inputs, follows, dir, non-flakes, modes, idempotence")

        # An unlocked nested input must be freshly resolved, even if the mutable
        # root was prefetched. It must not use the ordinary one-hour fetch TTL.
        nested_only = repository(base, "nested-only")
        unlocked = repository(base, "unlocked", {"dep.url": json.dumps(url(nested_only))})
        inputs["nested.url"] = json.dumps(url(unlocked))
        del inputs["alias.url"]
        inputs["added.url"] = json.dumps(url(leaf))
        write_flake(root, inputs)
        compare(root)
        (nested_only / "new.txt").write_text("another revision")
        latest = commit(nested_only)
        # Run the fast updater FIRST, before native Nix can refresh the cache.
        # This dependency is absent from the parallel root prefetch entirely.
        run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), cwd=root)
        graph = json.loads((root / "flake.lock").read_text())
        nodes = graph["nodes"]
        roots = nodes[graph["root"]]["inputs"]
        assert nodes[nodes[roots["nested"]]["inputs"]["dep"]]["locked"]["rev"] == latest
        compare(root)
        previous_nested = nodes[roots["nested"]]["locked"]["rev"]
        (leaf / "new.txt").write_text("targeted revision")
        targeted = commit(leaf)
        graph = compare(root, "a")
        nodes = graph["nodes"]
        roots = nodes[graph["root"]]["inputs"]
        assert nodes[roots["a"]]["locked"]["rev"] == targeted
        assert nodes[roots["nested"]]["locked"]["rev"] == previous_nested
        print("PASS: added/removed/changed declarations, fresh unlocked nested input, targeted update")

        before = (root / "flake.lock").read_bytes()
        inputs["broken.url"] = json.dumps(url(base / "missing"))
        write_flake(root, inputs)
        result = run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), cwd=root, check=False)
        assert result.returncode != 0
        assert (root / "flake.lock").read_bytes() == before
        assert not list(root.glob(".flake-update.*"))
        del inputs["broken.url"]
        write_flake(root, inputs)
        print("PASS: failed fetch leaves the lock untouched")

        # Change the file while native Nix validates the staged graph.
        wrapper = base / "bin"
        wrapper.mkdir()
        real_nix = shutil.which("nix")
        (wrapper / "nix").write_text(
            "#!/usr/bin/env python3\nimport os, pathlib, sys\n"
            "if 'metadata' in sys.argv:\n"
            "    with pathlib.Path('flake.nix').open('a') as f: f.write('\\n# concurrent edit\\n')\n"
            f"os.execv({real_nix!r}, [{real_nix!r}, *sys.argv[1:]])\n"
        )
        (wrapper / "nix").chmod(0o755)
        env = dict(os.environ, PATH=str(wrapper) + os.pathsep + os.environ["PATH"])
        result = run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), cwd=root, check=False, env=env)
        assert result.returncode != 0 and "changed during the update" in result.stderr
        assert (root / "flake.lock").read_bytes() == before
        assert not list(root.glob(".flake-update.*"))
        print("PASS: concurrent edit aborts without replacing the lock; staging cleaned")

        # Standard Nix has no parallel builtin. Exercise the same fallback by
        # disabling Determinate's extension for the resolver process.
        (wrapper / "nix").write_text(
            "#!/usr/bin/env python3\nimport os, sys\n"
            f"nix = {real_nix!r}\n"
            "os.execv(nix, [nix, '--option', 'experimental-features', 'nix-command flakes', *sys.argv[1:]])\n"
        )
        run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), cwd=root, env=env)
        compare(root)
        print("PASS: disabling parallel-eval uses native fallback")

        inputs["local.url"] = json.dumps("path:" + leaf.as_uri().removeprefix("file://"))
        write_flake(root, inputs)
        compare(root)
        expected_path = root / "expected.lock"
        run("nix", "flake", "update", "--output-lock-file", str(expected_path), cwd=root)
        run("nu", "--no-config-file", str(SCRIPT), "--flake", str(root), "--serial", cwd=root)
        assert json.loads(expected_path.read_text()) == json.loads((root / "flake.lock").read_text())
        print("PASS: unsupported input uses native fallback; explicit --serial matches native")


if __name__ == "__main__":
    main()
