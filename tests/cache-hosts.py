"""Build two hosts against a real shared Nix store without a shared planner."""

import json
import os
import platform
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".github/cache/host.sh"


class HostTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cache-hosts-test-")
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name)
        program = """import os
from pathlib import Path
name = os.environ['name']
if name == 'broken': raise SystemExit(17)
print('BUILT:' + name, flush=True)
Path(os.environ['out']).write_text(os.environ.get('dependency', name))
"""
        (self.work / "flake.nix").write_text('''
          {
            outputs = { self }: let
              make = name: dependency: derivation {
                inherit name dependency;
                system = builtins.currentSystem;
                builder = BUILDER;
                args = [ "-c" PROGRAM ];
              };
              shared = make "shared" "";
              host = name: { config.system.build.toplevel = make name shared; };
            in { nixosConfigurations = {
              desktop = host "desktop";
              zenbook = host "zenbook";
            }; };
          }
        '''.replace('BUILDER', json.dumps(sys.executable))
           .replace('PROGRAM', json.dumps(program))
           .replace('builtins.currentSystem', json.dumps(platform.machine() + "-linux")))
        scanner = self.work / "scanner"
        scanner.write_text(f'#!{sys.executable}\nimport sys, os\nfrom pathlib import Path\n'
                           'assert not any(os.environ.get(k) for k in ["NIX_CACHE_SSH_KEY", "NIX_CACHE_SIGNING_KEY"])\n'
                           'with Path("scans").open("a") as f: f.write(sys.argv[1] + "\\n")\n')
        scanner.chmod(0o755)
        self.env = dict(os.environ,
                        NIX_REMOTE="local", NIX_STORE_DIR=str(self.work / "store"),
                        NIX_STATE_DIR=str(self.work / "state"), NIX_LOG_DIR=str(self.work / "log"),
                        NIX_CONF_DIR=str(self.work / "etc"), NIX_USER_CONF_FILES="/dev/null",
                        XDG_CACHE_HOME=str(self.work / "cache"),
                        NIX_CONFIG="experimental-features = nix-command flakes\n"
                                   "build-users-group =\nsandbox = false\nsubstituters =\nplugin-files =\n",
                        RUNNER_TEMP=str(self.work), GITHUB_OUTPUT=str(self.work / "outputs"),
                        PUBLISH_CACHE="false", NIX_CACHE_SSH_KEY="fixture", NIX_CACHE_SIGNING_KEY="fixture",
                        SCANNER=str(scanner), SCAN_SCOPE="committed")

    def run_host(self, host):
        return subprocess.run(["bash", str(SCRIPT), host], cwd=self.work, env=self.env,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    def test_second_host_reuses_shared_output_without_a_planning_step(self):
        desktop = self.run_host("desktop")
        self.assertEqual(desktop.returncode, 0, desktop.stdout)
        zenbook = self.run_host("zenbook")
        self.assertEqual(zenbook.returncode, 0, zenbook.stdout)
        self.assertIn("BUILT:shared", desktop.stdout)
        self.assertNotIn("BUILT:shared", zenbook.stdout)
        self.assertIn("BUILT:zenbook", zenbook.stdout)
        self.assertEqual((self.work / "nixos-desktop").read_text(),
                         (self.work / "nixos-zenbook").read_text())
        self.assertEqual((self.work / "scans").read_text().splitlines(), [
            ".#nixosConfigurations.desktop.config.system.build.toplevel",
            ".#nixosConfigurations.zenbook.config.system.build.toplevel",
        ])

    def test_failed_build_does_not_start_a_scan(self):
        flake = self.work / "flake.nix"
        flake.write_text(flake.read_text().replace('host "desktop"', 'host "broken"'))
        result = self.run_host("desktop")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("builder failed", result.stdout)
        self.assertFalse((self.work / "scans").exists())
        self.assertFalse((self.work / "outputs").exists())


if __name__ == "__main__":
    unittest.main()
