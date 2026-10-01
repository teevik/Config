"""Check the update artifact boundary to the write-enabled PR job."""

import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("install_update", ROOT / ".github/cache/install-update.py")
update = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update)


class UpdateArtifactTests(unittest.TestCase):
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
