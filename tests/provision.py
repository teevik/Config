#!/usr/bin/env python3
"""Exercise provisioning with fake keys and a local SSH/installer transport."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/provision.sh"


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.base = Path(self.scratch.name)
        self.repo = self.base / "repo"
        (self.repo / "scripts").mkdir(parents=True)
        shutil.copy2(SCRIPT, self.repo / "scripts/provision.sh")
        (self.repo / "hosts/zenbook").mkdir(parents=True)
        (self.repo / "hosts/zenbook/disk-config.nix").write_text("{}\n")
        (self.repo / "hosts/zenbook/hardware.nix").write_text("old hardware\n")
        (self.repo / "deleted.txt").write_text("delete me\n")
        (self.repo / ".gitignore").write_text("ignored/\n")
        self.git("init", "--quiet")
        self.git("add", ".")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--quiet", "-m", "fixture")
        self.home = self.base / "local-home"
        for relative in (".ssh/id_rsa", ".ssh/id_rsa.pub", ".config/sops/age/keys.txt"):
            path = self.home / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("fixture key\n")
        self.remote = self.base / "remote"
        (self.remote / "etc").mkdir(parents=True)
        (self.remote / "etc/NIXOS").touch()
        (self.remote / "etc/os-release").write_text("ID=nixos\n")
        self.remote_home = self.remote / "home/teevik"
        shutil.copytree(self.home, self.remote_home)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "events.jsonl"
        self.env = os.environ | {
            "HOME": str(self.home),
            "PATH": str(self.bin) + os.pathsep + os.environ["PATH"],
            "PROVISION_REMOTE_ROOT": str(self.remote),
            "PROVISION_LOG": str(self.log),
        }
        self.mock("nix", '''
import json, os, pathlib, stat, sys
args = sys.argv[1:]
stage = pathlib.Path(args[args.index("--extra-files") + 1])
files = {str(p.relative_to(stage)): stat.S_IMODE(p.stat().st_mode)
         for p in stage.rglob("*") if p.is_file()}
assert all(p.read_text() == "fixture key\\n" for p in stage.rglob("*") if p.is_file())
with open(os.environ["PROVISION_LOG"], "a") as log:
    log.write(json.dumps({"kind": "nix", "args": args, "files": files}) + "\\n")
sys.exit(int(os.environ.get("PROVISION_NIX_EXIT", "0")))
''')
        self.mock("ssh", '''
import os, shlex, subprocess, sys
assert sys.argv[1:3] == ["--", "root@example.invalid"]
command = shlex.split(sys.argv[3])
assert command[:2] == ["bash", "-c"] and len(command) == 3
remote = os.environ["PROVISION_REMOTE_ROOT"]
script = command[2].replace("/etc/NIXOS", remote + "/etc/NIXOS")
script = script.replace("/etc/os-release", remote + "/etc/os-release")
script = script.replace("/home/teevik", remote + "/home/teevik")
sys.exit(subprocess.call(["bash", "-c", script]))
''')
        self.mock("getent", '''
import os, sys
assert sys.argv[1:] == ["passwd", "teevik"]
print("teevik:x:2345:777::" + os.environ["PROVISION_REMOTE_ROOT"] + "/home/teevik:/bin/bash")
''')
        self.mock("id", '''
import sys
assert sys.argv[1:] == ["-gn", "teevik"]
print("fixture-group")
''')
        self.mock("chown", '''
import json, os, sys
with open(os.environ["PROVISION_LOG"], "a") as log:
    log.write(json.dumps({"kind": "chown", "args": sys.argv[1:]}) + "\\n")
''')
        self.mock("systemctl", '''
import json, os, sys
assert sys.argv[1:] == ["restart", "hjem-activate@teevik.service", "hjem-reload@teevik.service", "hjem-update-state@teevik.service"]
with open(os.environ["PROVISION_LOG"], "a") as log:
    log.write(json.dumps({"kind": "systemctl", "args": sys.argv[1:]}) + "\\n")
''')

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True, text=True)

    def mock(self, name, body):
        path = self.bin / name
        path.write_text("#!" + shutil.which("python3") + "\n" + body)
        path.chmod(0o755)

    def run_script(self, action, *args):
        return subprocess.run(
            ["bash", str(self.repo / "scripts/provision.sh"), action, "example.invalid", *args],
            env=self.env, capture_output=True, text=True,
        )

    def events(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def test_install_stages_keys_privately_and_does_not_reboot(self):
        result = self.run_script("install", "zenbook")
        self.assertEqual(result.returncode, 0, result.stderr)
        event = self.events()[0]
        args = event["args"]
        self.assertEqual(args[args.index("--phases") + 1], "kexec,disko,install")
        self.assertEqual(event["files"], {
            "home/teevik/.ssh/id_rsa": 0o600,
            "home/teevik/.ssh/id_rsa.pub": 0o644,
            "home/teevik/.config/sops/age/keys.txt": 0o600,
        })
        self.assertFalse(Path(args[args.index("--extra-files") + 1]).exists())
        self.assertIn("just provision example.invalid", result.stdout)

    def test_missing_key_aborts_before_installer(self):
        (self.home / ".config/sops/age/keys.txt").unlink()
        result = self.run_script("install", "zenbook")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), [])

    def test_installer_failure_removes_private_stage(self):
        self.env["PROVISION_NIX_EXIT"] = "23"
        result = self.run_script("install", "zenbook")
        self.assertEqual(result.returncode, 23)
        args = self.events()[0]["args"]
        self.assertFalse(Path(args[args.index("--extra-files") + 1]).exists())

    def test_provision_preserves_local_changes_and_uses_actual_group(self):
        hardware = "hosts/zenbook/hardware.nix"
        (self.repo / hardware).write_text("generated hardware\n")
        (self.repo / "deleted.txt").unlink()
        (self.repo / "new.nix").write_text("new module\n")
        (self.repo / "ignored").mkdir()
        (self.repo / "ignored/artifact").write_text("build result\n")
        result = self.run_script("provision")
        self.assertEqual(result.returncode, 0, result.stderr)
        checkout = self.remote_home / "Documents/Config"
        self.assertEqual((checkout / hardware).read_text(), "generated hardware\n")
        self.assertTrue((checkout / "new.nix").is_file())
        self.assertTrue((checkout / ".git/HEAD").is_file())
        self.assertFalse((checkout / "deleted.txt").exists())
        self.assertFalse((checkout / "ignored").exists())
        self.assertTrue(all("teevik:fixture-group" in e["args"] for e in self.events() if e["kind"] == "chown"))
        self.assertEqual(self.events()[-1]["kind"], "systemctl")
        self.assertEqual((self.remote_home / ".ssh/id_rsa").stat().st_mode & 0o777, 0o600)
        repeat = self.run_script("provision")
        self.assertNotEqual(repeat.returncode, 0)
        self.assertIn("existing Config checkout", repeat.stderr)
        self.assertEqual((checkout / hardware).read_text(), "generated hardware\n")

    def test_provision_rejects_live_installer(self):
        (self.remote / "etc/os-release").write_text("ID=nixos\nVARIANT_ID=installer\n")
        result = self.run_script("provision")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Boot the installed system", result.stderr)
        self.assertFalse((self.remote_home / "Documents/Config").exists())

    def test_provision_rejects_linked_worktree(self):
        shutil.rmtree(self.repo / ".git")
        (self.repo / ".git").write_text("gitdir: /unavailable\n")
        result = self.run_script("provision")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("normal Git checkout", result.stderr)


if __name__ == "__main__":
    unittest.main()
