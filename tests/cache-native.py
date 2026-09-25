"""Check native publication and the boundary to the write-enabled PR job."""

import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".github/cache"))
import publish

spec = importlib.util.spec_from_file_location("install_update", ROOT / ".github/cache/install-update.py")
update = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update)


class NativeTests(unittest.TestCase):
    def test_native_publish_has_no_signing_or_ssh_credentials(self):
        path = "/nix/store/" + "0" * 32 + "-nixos-system-desktop-test"
        info = {path: {"narSize": 10}}
        receipt = {"closureDigest": publish.closure_digest(info), "closurePaths": 1}
        with patch.dict(os.environ, {"NIX_CACHE_LOCAL_SOCKET": "/test/socket"}, clear=True), \
             patch.object(publish, "closure_info", return_value=info), \
             patch.object(publish, "local_request", return_value=receipt) as request, \
             patch.object(publish.subprocess, "run") as execute, \
             patch.object(publish, "check_cached") as check:
            publish.publish("desktop", "1-1", path)
        request.assert_called_once_with("publish", host="desktop", generation="1-1", path=path)
        self.assertEqual(execute.call_count, 1)
        self.assertEqual(execute.call_args.args[0][:3], ["nix", "store", "verify"])
        check.assert_called_once_with(path)

    def fixture(self, root, artifact):
        (root / "packages").mkdir()
        (root / "packages/update-packages.json").write_text('{"test":"flake.lock"}')
        (root / "flake.lock").write_text("old")
        (artifact / "sources").mkdir(parents=True)
        (artifact / "sources/flake.lock").write_text("new")
        (artifact / "files.txt").write_text("flake.lock\n")

    def test_installs_only_catalog_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root, artifact = Path(directory), Path(directory) / "artifact"
            self.fixture(root, artifact)
            update.install(root, artifact)
            self.assertEqual((root / "flake.lock").read_text(), "new")

    def test_rejects_git_injection_symlinks_and_changed_catalog(self):
        for attack in ["git", "symlink", "manifest", "catalog"]:
            with self.subTest(attack=attack), tempfile.TemporaryDirectory() as directory:
                root, artifact = Path(directory), Path(directory) / "artifact"
                self.fixture(root, artifact)
                if attack == "git":
                    (artifact / "sources/.git").mkdir()
                    (artifact / "sources/.git/config").write_text("malicious hooks")
                elif attack == "symlink":
                    (artifact / "sources/flake.lock").unlink()
                    (artifact / "sources/flake.lock").symlink_to(root / "flake.lock")
                elif attack == "manifest":
                    (artifact / "files.txt").write_text("../outside\n")
                else:
                    (artifact / "sources/packages").mkdir()
                    (artifact / "sources/packages/update-packages.json").write_text("{}")
                with self.assertRaises(ValueError):
                    update.install(root, artifact)
                self.assertEqual((root / "flake.lock").read_text(), "old")


if __name__ == "__main__":
    unittest.main()
