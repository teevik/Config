"""Check the update artifact boundary to the write-enabled PR job."""

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("install_update", ROOT / ".github/ci/install-update.py")
update = importlib.util.module_from_spec(spec)
spec.loader.exec_module(update)


class UpdateArtifactTests(unittest.TestCase):
    def fixture(self, root, artifact):
        (root / "packages").mkdir()
        (root / "packages/update-packages.json").write_text('{"other":"packages/other.nix","test":"packages/test.nix"}')
        (root / "packages/test.nix").write_text("old package")
        (root / "packages/other.nix").write_text("old other")
        (root / "flake.lock").write_text("old")
        (artifact / "sources").mkdir(parents=True)
        (artifact / "sources/flake.lock").write_text("new")
        (artifact / "sources/packages").mkdir()
        (artifact / "sources/packages/test.nix").write_text("new package")
        (artifact / "files.txt").write_text("flake.lock\npackages/test.nix\n")

    def test_installs_only_catalog_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root, artifact = Path(directory), Path(directory) / "artifact"
            self.fixture(root, artifact)
            update.install(root, artifact)
            self.assertEqual((root / "flake.lock").read_text(), "new")
            self.assertEqual((root / "packages/test.nix").read_text(), "new package")

    def test_installs_subset_left_after_failed_updates(self):
        with tempfile.TemporaryDirectory() as directory:
            root, artifact = Path(directory), Path(directory) / "artifact"
            self.fixture(root, artifact)
            (artifact / "sources/flake.lock").unlink()
            (artifact / "files.txt").write_text("packages/test.nix\n")
            (artifact / "failures.json").write_text('[{"label": "all flake inputs", "error": "boom"}]')
            update.install(root, artifact)
            self.assertEqual((root / "flake.lock").read_text(), "old")
            self.assertEqual((root / "packages/test.nix").read_text(), "new package")
            self.assertEqual((root / "packages/other.nix").read_text(), "old other")

    def test_accepts_export_manifest_for_repository_catalog(self):
        catalog = (ROOT / "packages/update-packages.json").read_text()
        files = sorted({"flake.lock", *json.loads(catalog).values()})
        with tempfile.TemporaryDirectory() as directory:
            root, artifact = Path(directory), Path(directory) / "artifact"
            (root / "packages").mkdir()
            (root / "packages/update-packages.json").write_text(catalog)
            for name in files:
                (root / name).write_text("old")
                source = artifact / "sources" / name
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_text("new " + name)
            (artifact / "files.txt").write_text("\n".join(files) + "\n")
            update.install(root, artifact)
            for name in files:
                self.assertEqual((root / name).read_text(), "new " + name)

    def test_rejects_unsafe_or_inconsistent_artifacts(self):
        attacks = ["git", "symlink", "manifest", "catalog", "empty", "unlisted", "missing", "unsorted", "uncataloged"]
        for attack in attacks:
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
                elif attack == "empty":
                    for name in ["flake.lock", "packages/test.nix"]:
                        (artifact / "sources" / name).unlink()
                    (artifact / "files.txt").write_text("")
                elif attack == "unlisted":
                    # A subset manifest must still describe every shipped file.
                    (artifact / "files.txt").write_text("packages/test.nix\n")
                elif attack == "missing":
                    (artifact / "sources/packages/test.nix").unlink()
                elif attack == "unsorted":
                    (artifact / "files.txt").write_text("packages/test.nix\nflake.lock\n")
                elif attack == "uncataloged":
                    (artifact / "sources/packages/extra.nix").write_text("not in the catalog")
                    (artifact / "files.txt").write_text("flake.lock\npackages/extra.nix\npackages/test.nix\n")
                else:
                    (artifact / "sources/packages/update-packages.json").write_text("{}")
                with self.assertRaises(ValueError):
                    update.install(root, artifact)
                self.assertEqual((root / "flake.lock").read_text(), "old")
                self.assertEqual((root / "packages/test.nix").read_text(), "old package")


if __name__ == "__main__":
    unittest.main()
