"""Check crate derivation inputs across unrelated and relevant workspace edits."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SourceTests(unittest.TestCase):
    def test_workspace_dependencies_are_independent_but_metadata_and_assets_are_tracked(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for variant in ["original", "dependency", "edition", "source", "asset"]:
                directory = root / variant
                (directory / "crates/settings").mkdir(parents=True)
                (directory / "assets").mkdir()
                edition = "2021" if variant == "edition" else "2024"
                version = "0.4.2" if variant == "dependency" else "0.3.3"
                (directory / "Cargo.toml").write_text(
                    f'[workspace.package]\nedition="{edition}"\n'
                    f'[workspace.dependencies]\nyawc="{version}"\n')
                (directory / "crates/settings/Cargo.toml").write_text(
                    '[package]\nname="settings"\nversion="0.1.0"\nedition.workspace=true\n')
                (directory / "crates/settings/lib.rs").write_text("changed" if variant == "source" else "original")
                (directory / "assets/default.json").write_text("changed" if variant == "asset" else "original")
            pkgs = ("import " + json.dumps(os.environ["NIXPKGS_SOURCE"]) + " {}"
                    if "NIXPKGS_SOURCE" in os.environ else f"import {ROOT}/packages/nix-lint/pkgs.nix")
            expression = '''
              let
                pkgs = PKGS;
                sourceFor = variant: import LOCAL_SOURCE {
                  inherit pkgs;
                  source = builtins.path { path = ROOT + "/${variant}"; name = "source"; };
                } "crates/settings";
                # These are the source and patch consumed by buildRustCrate.
                drv = variant: let input = sourceFor variant; in
                  (pkgs.runCommand "crate-inputs" { inherit (input) src; } input.postPatch).drvPath;
                original = sourceFor "original";
              in {
                unrelatedDependencyReused = drv "original" == drv "dependency";
                inheritedEditionTracked = drv "original" != drv "edition";
                ownSourceTracked = drv "original" != drv "source";
                sharedAssetsTracked = drv "original" != drv "asset";
                crateManifestPreserved = builtins.readFile "${original.src}/crates/settings/Cargo.toml"
                  == builtins.readFile (ROOT + "/original/crates/settings/Cargo.toml");
              }
            '''.replace("PKGS", pkgs).replace("LOCAL_SOURCE", str(ROOT / "packages/zed/local-source.nix")).replace("ROOT", json.dumps(str(root)))
            result = json.loads(subprocess.check_output([
                "nix", "eval", "--impure", "--json", "--expr", expression,
            ], text=True))
            for property, passed in result.items():
                self.assertTrue(passed, property)


if __name__ == "__main__":
    unittest.main()
