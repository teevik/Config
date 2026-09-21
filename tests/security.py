"""Exercise the security report's disclosure boundary and failure behavior."""

import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / "packages/security" / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class InventoryTests(unittest.TestCase):
    def test_transitive_pins_become_root_inputs(self):
        lock = {"version": 7, "root": "project", "nodes": {
            "project": {"inputs": {"nixpkgs": "nixpkgs_5", "private": "private"}},
            "nixpkgs_5": {"original": {"repo": "nixpkgs"}},
            "older": {"original": {"repo": "nixpkgs"}},
            "private": {"inputs": {"nixpkgs": "older"}},
        }}
        projected, keys = load("lock_inputs").project(lock)
        self.assertEqual(keys, "nixpkgs_5,older")
        self.assertEqual(projected["nodes"][projected["root"]]["inputs"], {
            "nixpkgs_5": "nixpkgs_5", "older": "older",
        })
        self.assertEqual(lock["root"], "project")
        self.assertNotIn("security-check-root", lock["nodes"])

    def test_no_inventory_is_not_a_clean_scan(self):
        with self.assertRaises(ValueError):
            load("scan").summarize({"components": []}, {"matches": []})
        with self.assertRaises(ValueError):
            load("scan").summarize({"components": [{}]}, {})


# Test stand-ins exercise process invocation and real age encryption. They
# deliberately put private identifiers into both the reports and diagnostics.
FAKE_TOOL = r'''
import json, os, pathlib, sys
tool = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
secret = "private-project-identifier"
if tool == "nix":
    print("nix-test" if "--version" in args else "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-system")
elif tool == "sbomnix":
    assert "post-build-hook =\n" in os.environ["NIX_CONFIG"]
    if os.environ.get("FAKE_SCAN_FAIL") == "sbom":
        print(secret, file=sys.stderr)
        sys.exit(1)
    for option in ["--cdx", "--spdx", "--csv"]:
        pathlib.Path(args[args.index(option) + 1]).write_text(json.dumps({
            "bomFormat": "CycloneDX", "components": [{"name": secret}]
        }))
    print(secret, file=sys.stderr)
elif tool == "grype":
    if "version" in args:
        print('{"version":"test"}')
    elif "update" in args:
        if os.environ.get("FAKE_SCAN_FAIL") == "database":
            print(secret, file=sys.stderr)
            sys.exit(1)
    elif "status" in args:
        print('{"status":"valid"}')
    elif "--file" in args:
        if os.environ.get("FAKE_SCAN_FAIL") == "scanner":
            print(secret, file=sys.stderr)
            sys.exit(1)
        match = {"artifact": {"name": secret, "version": "1"},
                 "vulnerability": {"id": "CVE-2000-0001", "severity": "High"}}
        pathlib.Path(args[args.index("--file") + 1]).write_text(json.dumps({"matches": [match, match]}))
'''


class ReportingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.work = Path(self.temp.name)
        self.identity = self.work / "identity"
        subprocess.run(["age-keygen", "-o", str(self.identity)], check=True, capture_output=True)
        public = subprocess.run(["age-keygen", "-y", str(self.identity)], check=True, capture_output=True, text=True).stdout
        self.recipients = self.work / "recipients"
        self.recipients.write_text(public)
        self.bin = self.work / "bin"
        self.bin.mkdir()
        for name in ("nix", "sbomnix", "grype"):
            tool = self.bin / name
            tool.write_text(f"#!{sys.executable}\n" + FAKE_TOOL)
            tool.chmod(0o755)
        self.output = self.work / "report"
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        GITHUB_STEP_SUMMARY=str(self.work / "job-summary"))

    def scan(self, *extra):
        return subprocess.run([
            sys.executable, str(ROOT / "packages/security/scan.py"), "private-target",
            "--scope", "candidate", "--output", str(self.output),
            "--recipients", str(self.recipients), *extra,
        ], env=self.env, text=True, capture_output=True, cwd=self.work)

    def decrypt(self):
        result = subprocess.run([
            "age", "--decrypt", "--identity", str(self.identity),
            str(self.output / "report.tar.gz.age"),
        ], check=True, capture_output=True)
        return tarfile.open(fileobj=io.BytesIO(result.stdout), mode="r:gz")

    def assert_public_is_private(self, result):
        public = result.stdout + result.stderr
        for path in self.output.iterdir():
            if path.suffix != ".age":
                public += path.read_text()
        public += (self.work / "job-summary").read_text()
        self.assertNotIn("private-project-identifier", public)
        self.assertNotIn("private-target", public)
        self.assertNotIn("CVE-2000-0001", public)

    def test_findings_succeed_and_details_are_encrypted(self):
        result = self.scan()
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        summary = json.loads((self.output / "summary.json").read_text())
        self.assertEqual(summary["status"], "complete")
        self.assertEqual(summary["findings"], 1)
        self.assertEqual(summary["severity"]["High"], 1)
        self.assert_public_is_private(result)
        with self.decrypt() as archive:
            findings = archive.extractfile("vulnerabilities.json").read().decode()
            self.assertIn("private-project-identifier", findings)
            self.assertIn("sbom.cdx.json", archive.getnames())

    def test_scanner_and_database_failures_are_not_clean_scans(self):
        for phase in ("sbom", "database", "scanner"):
            with self.subTest(phase=phase):
                self.output = self.work / phase
                self.env["FAKE_SCAN_FAIL"] = phase
                result = self.scan()
                self.assertEqual(result.returncode, 1)
                summary = json.loads((self.output / "summary.json").read_text())
                self.assertEqual(summary["status"], "incomplete")
                self.assertNotIn("findings", summary)
                self.assert_public_is_private(result)
                with self.decrypt() as archive:
                    self.assertIn("private-project-identifier", archive.extractfile("scan.log").read().decode())

    def test_encryption_failure_never_publishes_plaintext(self):
        self.recipients.write_text("not-an-age-recipient\n")
        result = self.scan()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("private-project-identifier", result.stdout + result.stderr)
        self.assertFalse((self.output / "summary.json").exists())
        self.assertFalse((self.output / "sbom.cdx.json").exists())

    def test_previous_output_cannot_be_reused_as_success(self):
        self.output.mkdir()
        (self.output / "summary.json").write_text("old")
        result = self.scan()
        self.assertEqual(result.returncode, 1)
        self.assertEqual((self.output / "summary.json").read_text(), "old")


if __name__ == "__main__":
    unittest.main()
