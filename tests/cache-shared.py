"""Exercise shared planning and output selection with real Nix derivations."""

import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / ".github/cache/shared.py"
spec = importlib.util.spec_from_file_location("shared", SCRIPT)
shared = importlib.util.module_from_spec(spec)
spec.loader.exec_module(shared)


class SharedTests(unittest.TestCase):
    def test_graph_boundary_keeps_required_outputs_and_skips_unneeded_build_inputs(self):
        graph = {name: {"inputDrvs": deps} for name, deps in {
            "desktop": {"zed": ["out"], "kernel-a": ["out"], "toolchain": ["dev"]},
            "zenbook": {"zed": ["out"], "kernel-b": ["out"], "toolchain": ["out"]},
            "zed": {"rust": ["out"]}, "rust": {}, "toolchain": {},
            "kernel-a": {"headers": ["out"]}, "kernel-b": {"headers": ["out"]}, "headers": {},
        }.items()}
        self.assertEqual(shared.shared_dependencies(graph, ["desktop", "zenbook"]), {
            "headers": ["out"], "toolchain": ["dev", "out"], "zed": ["out"],
        })

    def test_real_multi_output_dependency_is_built_once_before_either_host(self):
        with tempfile.TemporaryDirectory(prefix="cache-shared-test-") as temporary:
            work = Path(temporary)
            program = "import os\nfor name in os.environ['outputs'].split(): os.mkdir(os.environ[name])"
            (work / "flake.nix").write_text('''
              { outputs = { self }: let
                make = name: outputs: derivation {
                  inherit name outputs;
                  system = "x86_64-linux";
                  builder = BUILDER;
                  args = [ "-c" PROGRAM ];
                };
                dep = make "shared-editor" [ "out" "lib" "doc" ];
                host = name: output: derivation {
                  inherit name;
                  system = "x86_64-linux";
                  builder = "/host-must-not-build-during-preparation";
                  dependency = output;
                };
              in { packages.x86_64-linux = {
                desktop = host "desktop" dep.out;
                zenbook = host "zenbook" dep.lib;
              }; }; }
            '''.replace("BUILDER", json.dumps(sys.executable)).replace("PROGRAM", json.dumps(program)))
            env = dict(os.environ, NIX_REMOTE="local", NIX_STORE_DIR=str(work / "store"),
                       NIX_STATE_DIR=str(work / "state"), NIX_LOG_DIR=str(work / "log"),
                       NIX_CONF_DIR=str(work / "etc"), NIX_USER_CONF_FILES="/dev/null",
                       XDG_CACHE_HOME=str(work / "cache"),
                       NIX_CONFIG="experimental-features = nix-command flakes\n"
                                  "build-users-group =\nsandbox = false\nsubstituters =\nplugin-files =\n")
            directory = work / "plan"
            subprocess.run([sys.executable, str(SCRIPT), "plan", str(directory),
                            ".#desktop", ".#zenbook"], cwd=work, env=env, check=True)
            plan = json.loads((directory / "shared-plan.json").read_text())
            self.assertEqual(len(plan), 1)
            self.assertEqual(next(iter(plan.values())), ["lib", "out"])
            subprocess.run([sys.executable, str(SCRIPT), "build", str(directory)], cwd=work, env=env, check=True)
            paths = (directory / "shared-paths").read_text().splitlines()
            self.assertEqual(len(paths), 2)
            self.assertTrue(all(Path(path).is_dir() for path in paths))
            self.assertTrue(any(path.endswith("-lib") for path in paths))
            self.assertFalse(any(path.endswith("-doc") for path in paths))

    def test_unknown_json_versions_fail_instead_of_producing_an_empty_plan(self):
        with self.assertRaises(ValueError):
            shared.derivations({"version": 99, "derivations": {}})


if __name__ == "__main__":
    unittest.main()
