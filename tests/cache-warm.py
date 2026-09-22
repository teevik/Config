"""Local integration test: preserve build-only outputs without realizing missing ones."""

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("warm", ROOT / ".github/cache/warm.py")
warm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(warm)
FIXTURE = str(ROOT / "tests/cache-warm.nix")


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def main():
    result = json.loads(run(
        "nix", "build", "--file", FIXTURE, "result", "--no-link", "--json",
        "--option", "builders", "", "--option", "post-build-hook", "",
    ))[0]
    output = result["outputs"]["out"]
    intermediate_drv = run("nix-instantiate", FIXTURE, "--attr", "intermediate")
    intermediate = run("nix-store", "--query", "--outputs", intermediate_drv)
    missing_drv = run("nix-instantiate", FIXTURE, "--attr", "unbuilt")
    missing = run("nix-store", "--query", "--outputs", missing_drv)
    assert not Path(missing).exists()
    assert intermediate not in run("nix-store", "--query", "--requisites", output).splitlines()

    with tempfile.TemporaryDirectory(prefix="cache-warm-test-") as directory:
        work = Path(directory)
        manifest = work / "paths.txt"
        # The default is inventory only, even if given an unreachable store.
        subprocess.run([
            "python3", str(ROOT / ".github/cache/warm.py"), output, missing_drv,
            "--store", "ssh-ng://unreachable.invalid", "--manifest", str(manifest),
        ], check=True)
        paths = set(manifest.read_text().splitlines())
        assert {output, result["drvPath"], intermediate, intermediate_drv, missing_drv} <= paths
        assert missing not in paths and not Path(missing).exists()

        cache = (work / "cache").as_uri()
        warm.copy_paths([output, intermediate, missing_drv], cache, Path("/unused"))
        copied = set(run("nix", "path-info", "--store", cache, output, intermediate).splitlines())
        assert copied == {output, intermediate}
        absent = subprocess.run(["nix", "path-info", "--store", cache, missing_drv],
                                capture_output=True)
        assert absent.returncode != 0
    print("PASS: build-only outputs copied; runtime closure alone omitted them; missing outputs never built")


if __name__ == "__main__":
    main()
