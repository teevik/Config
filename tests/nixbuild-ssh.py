"""Exercise daemon SSH authentication with the real OpenSSH config parser."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DaemonSshTest(unittest.TestCase):
    def test_token_survives_a_cleared_daemon_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            upstream = work / "upstream"
            # nixbuild-action v27 forwards the current token via SendEnv.
            # Its legacy lowercase token entry alone does not authenticate
            # the remote store when sudo/the daemon clears the environment.
            upstream.write_text('''Host nixbuild eu.nixbuild.net
  HostName eu.nixbuild.net
  User authtoken
  PreferredAuthentications none
  SendEnv NIXBUILDNET_TOKEN
  SetEnv token="legacy-token" NIXBUILDNET_MAX_CPU="8" NIXBUILDNET_KEEP_BUILDS_RUNNING="false"
''')
            env = dict(os.environ, NIXBUILDNET_TOKEN="current-ci-token")
            rendered = subprocess.check_output([
                "bash", str(ROOT / ".github/actions/nixbuild/daemon-ssh.sh"), str(upstream),
            ], text=True, env=env)
            daemon = work / "daemon"
            daemon.write_text(rendered + "\nHost *\nHost github.com\n  User git\n")
            # No NIXBUILDNET_TOKEN or NIX_SSHOPTS reaches the daemon process.
            clean_env = {"PATH": os.environ["PATH"]}
            effective = subprocess.check_output([
                "ssh", "-G", "-F", str(daemon), "nixbuild",
            ], text=True, env=clean_env, stderr=subprocess.DEVNULL)
            settings = effective.splitlines()
            self.assertIn("setenv NIXBUILDNET_TOKEN=current-ci-token", settings)
            self.assertIn("hostname eu.nixbuild.net", settings)
            self.assertIn("user authtoken", settings)
            self.assertTrue(any(line.startswith("setenv NIXBUILDNET_MAX_CPU=") for line in settings))
            self.assertTrue(any(line.startswith("setenv NIXBUILDNET_KEEP_BUILDS_RUNNING=") for line in settings))
            other = subprocess.check_output([
                "ssh", "-G", "-F", str(daemon), "github.com",
            ], text=True, env=clean_env, stderr=subprocess.DEVNULL)
            self.assertNotIn("current-ci-token", other)
            self.assertIn("user git", other.splitlines())


if __name__ == "__main__":
    unittest.main()
