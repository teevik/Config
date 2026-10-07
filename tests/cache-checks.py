"""Exercise flake checks and cached-result retention with a real Nix store."""

import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / ".github/cache/check.sh"


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="cache-checks-test-")
        self.addCleanup(self.temporary.cleanup)
        self.work = Path(self.temporary.name)
        self.checkout = self.work / "checkout"
        self.checkout.mkdir()
        program = '''import os
from pathlib import Path
if os.environ['name'] == 'broken': raise SystemExit(17)
print('BUILT:' + os.environ['name'], flush=True)
Path(os.environ['out']).write_text('checked')
'''
        self.flake = '''{
          outputs = _: let
            make = name: derivation {
              inherit name;
              system = SYSTEM;
              builder = BUILDER;
              args = [ "-c" PROGRAM ];
            };
          in { checks.SYSTEM = { good = make "good"; EXTRA }; };
        }'''.replace('SYSTEM', json.dumps(platform.machine() + "-linux")) \
           .replace('BUILDER', json.dumps(sys.executable)) \
           .replace('PROGRAM', json.dumps(program))
        (self.checkout / "flake.nix").write_text(self.flake.replace('EXTRA', ''))
        scripts = self.checkout / ".github/cache"
        scripts.mkdir(parents=True)
        # The existing uploader has its own integration tests. This stand-in
        # leaves Nix untouched and observes the final retention manifest.
        (scripts / "build.py").write_text('''import subprocess, sys
raise SystemExit(subprocess.run(sys.argv[sys.argv.index('--') + 1:]).returncode)
''')
        (scripts / "publish.py").write_text('''import json, os, sys
from pathlib import Path
assert sys.argv[1:3] == ['--dependencies', 'bootstrap']
paths = Path(sys.argv[4]).read_text().splitlines()
assert all(Path(path).exists() for path in paths)
Path('retained.json').write_text(json.dumps(paths))
raise SystemExit(int(os.environ.get('FAIL_PUBLICATION', '0')))
''')
        self.cache = self.work / "binary-cache"
        self.env = dict(os.environ,
                        NIX_REMOTE="local", NIX_STORE_DIR=str(self.work / "store"),
                        NIX_STATE_DIR=str(self.work / "state"), NIX_LOG_DIR=str(self.work / "log"),
                        NIX_CONF_DIR=str(self.work / "etc"), NIX_USER_CONF_FILES="/dev/null",
                        XDG_CACHE_HOME=str(self.work / "cache"),
                        NIX_CONFIG="experimental-features = nix-command flakes\n"
                                   "build-users-group =\nsandbox = false\nsubstituters =\nplugin-files =\n",
                        RUNNER_TEMP=str(self.work), GITHUB_RUN_ID="123", GITHUB_RUN_ATTEMPT="1",
                        PUBLISH_CACHE="false")

    def command(self, *args):
        return subprocess.run(args, cwd=self.checkout, env=self.env, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    def check(self):
        return self.command("bash", str(SCRIPT))

    def outputs(self):
        return sorted({str(path.resolve()) for path in self.work.glob("flake-check*")
                       if path.is_symlink()})

    def test_second_run_substitutes_and_retains_without_rebuilding(self):
        first = self.check()
        self.assertEqual(first.returncode, 0, first.stdout)
        self.assertIn("BUILT:good", first.stdout)
        outputs = self.outputs()
        self.assertEqual(len(outputs), 1)
        copy = self.command("nix", "copy", "--to", self.cache.as_uri(), *outputs)
        self.assertEqual(copy.returncode, 0, copy.stdout)
        for link in self.work.glob("flake-check*"):
            if link.is_symlink():
                link.unlink()
        deleted = self.command("nix-store", "--delete", *outputs)
        self.assertEqual(deleted.returncode, 0, deleted.stdout)
        self.assertFalse(Path(outputs[0]).exists())

        self.env["NIX_CONFIG"] += f"substituters = {self.cache.as_uri()}\nrequire-sigs = false\n"
        self.env["PUBLISH_CACHE"] = "true"
        second = self.check()
        self.assertEqual(second.returncode, 0, second.stdout)
        self.assertNotIn("BUILT:good", second.stdout)
        self.assertIn("copying path", second.stdout)
        self.assertEqual(self.outputs(), outputs)
        self.assertEqual(json.loads((self.checkout / "retained.json").read_text()), outputs)

    def test_failed_check_still_retains_successful_outputs(self):
        (self.checkout / "flake.nix").write_text(self.flake.replace('EXTRA', 'bad = make "broken";'))
        self.env["PUBLISH_CACHE"] = "true"
        result = self.check()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("builder failed", result.stdout)
        outputs = self.outputs()
        self.assertEqual(len(outputs), 1)
        self.assertEqual(json.loads((self.checkout / "retained.json").read_text()), outputs)

    def test_failed_retention_fails_an_otherwise_successful_check(self):
        self.env.update(PUBLISH_CACHE="true", FAIL_PUBLICATION="9")
        result = self.check()
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertEqual(len(self.outputs()), 1)


if __name__ == "__main__":
    unittest.main()
