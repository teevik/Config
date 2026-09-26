"""Exercise the bootstrap handoff with Nix's real multi-output selection."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


BOOTSTRAP = Path(__file__).resolve().parents[1] / ".github/cache/bootstrap.sh"


class BootstrapTests(unittest.TestCase):
    def test_manifest_contains_runtime_and_plugin_not_the_manual_output(self):
        with tempfile.TemporaryDirectory(prefix="cache-bootstrap-test-") as temporary:
            work = Path(temporary)
            builder = json.dumps(sys.executable)
            program = json.dumps("import os\nfor name in os.environ['outputs'].split(): os.mkdir(os.environ[name])")
            (work / "flake.nix").write_text('''
              {
                outputs = { self }: let
                  packages = system: let
                    make = name: outputs: derivation {
                      inherit name outputs system;
                      builder = BUILDER;
                      args = [ "-c" PROGRAM ];
                    };
                    nix = (make "bootstrap-nix" [ "out" "man" ]) // {
                      meta.outputsToInstall = [ "out" "man" ];
                    };
                  in {
                    cargo-nix-plugin = (make "bootstrap-plugin" [ "out" ]) // { inherit nix; };
                  };
                in {
                  packages.x86_64-linux = packages "x86_64-linux";
                  packages.aarch64-linux = packages "aarch64-linux";
                };
              }
            '''.replace("BUILDER", builder).replace("PROGRAM", program))
            env = dict(os.environ,
                       NIX_REMOTE="local", NIX_STORE_DIR=str(work / "store"),
                       NIX_STATE_DIR=str(work / "state"), NIX_LOG_DIR=str(work / "log"),
                       NIX_CONF_DIR=str(work / "etc"), NIX_USER_CONF_FILES="/dev/null",
                       XDG_CACHE_HOME=str(work / "cache"),
                       NIX_CONFIG="experimental-features = nix-command flakes\n"
                                  "build-users-group =\nsandbox = false\nsubstituters =\nplugin-files =\n")
            manifest = work / "bootstrap-paths"
            subprocess.run(["bash", str(BOOTSTRAP), str(manifest)], cwd=work, env=env, check=True)
            expected = json.loads(subprocess.check_output([
                "nix", "eval", "--json", ".#cargo-nix-plugin",
                "--apply", "p: [ p.nix.outPath p.outPath ]",
            ], cwd=work, env=env, text=True))
            self.assertEqual(manifest.read_text().splitlines(), expected,
                             "The loader needs exactly the Nix runtime and plugin, in that order")
            # A cache hit does not run the retention hook. Keep the tools alive
            # during the job even if host GC runs before system publication.
            subprocess.run(["nix-store", "--gc"], cwd=work, env=env, check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.assertTrue(all(Path(path).exists() for path in expected),
                            "The running job must root both bootstrap outputs")


if __name__ == "__main__":
    unittest.main()
