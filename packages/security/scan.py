"""Generate a runtime SBOM and encrypt the detailed vulnerability report.

Only aggregate counts leave the encrypted bundle. Grype matches locally against
its downloaded database; component names are not sent to an advisory API.
"""

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import traceback


SEVERITIES = ("Critical", "High", "Medium", "Low", "Negligible", "Unknown")


def summarize(sbom, report):
    """Count unique component/advisory pairs, without exporting identifiers."""
    components = sbom.get("components")
    matches = report.get("matches")
    if not isinstance(components, list) or not components:
        raise ValueError("Missing or empty SBOM components")
    if not isinstance(matches, list):
        raise ValueError("Missing scanner matches")
    findings = {}
    for match in matches:
        artifact = match["artifact"]
        vulnerability = match["vulnerability"]
        key = (artifact["name"], artifact["version"], vulnerability["id"])
        severity = vulnerability["severity"].title()
        if severity not in SEVERITIES:
            severity = "Unknown"
        previous = findings.get(key, "Unknown")
        findings[key] = min((previous, severity), key=SEVERITIES.index)
    counts = Counter(findings.values())
    return {
        "components": len(components),
        "findings": len(findings),
        "severity": {severity: counts[severity] for severity in SEVERITIES},
    }


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def run_scan(args):
    os.umask(0o077)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise ValueError("Output directory must be empty")
    recipient = args.recipients.resolve()
    if not recipient.is_file():
        raise ValueError("Missing age recipient file")
    env = os.environ.copy()
    # A scan may realize derivations during metadata discovery. Never inherit
    # an unguarded Cachix hook installed for the preceding CI build.
    env["NIX_CONFIG"] = env.get("NIX_CONFIG", "") + "\npost-build-hook =\n"
    env.update({
        "GRYPE_CHECK_FOR_APP_UPDATE": "false",
        "GRYPE_DB_VALIDATE_AGE": "true",
        "GRYPE_DB_MAX_ALLOWED_BUILT_AGE": "168h",
        "GRYPE_DB_REQUIRE_UPDATE_CHECK": "true",
        "GRYPE_FAIL_ON_SEVERITY": "",
    })
    summary = {
        "status": "incomplete",
        "scope": args.scope,
        "scanned_at": datetime.now(timezone.utc).isoformat(),
    }
    phase = "initialization"
    failed = False
    with tempfile.TemporaryDirectory(prefix="nix-security-") as directory:
        raw = Path(directory)
        metadata = dict(summary, target=args.target, scanner_source="f3c241a49b27af9774894ad3cfb250d4d87280d8")

        def run(command):
            # Scanner diagnostics may contain private store paths; encrypt them.
            with (raw / "scan.log").open("ab") as log:
                result = subprocess.run(command, stdout=subprocess.PIPE, stderr=log, env=env, check=False)
                if result.returncode:
                    log.write(result.stdout)
                    raise RuntimeError("Command failed")
                return result.stdout.decode()

        try:
            phase = "recording the target"
            if not args.sbom:
                paths = run(["nix", "path-info", "--no-update-lock-file", args.target]).splitlines()
                if len(paths) != 1 or not paths[0].startswith("/nix/store/") or paths[0].endswith(".drv"):
                    raise ValueError("Expected one realized runtime output")
                metadata["store_path"] = paths[0]
            lock = Path("flake.lock")
            if lock.is_file():
                metadata["lock_sha256"] = hashlib.sha256(lock.read_bytes()).hexdigest()
            if revision := os.environ.get("GITHUB_SHA"):
                metadata["repository_revision"] = revision
            metadata["nix_version"] = run(["nix", "--version"]).strip()
            metadata["grype_version"] = run(["grype", "version", "-o", "json"])

            phase = "generating the SBOM"
            cdx = raw / "sbom.cdx.json"
            if args.sbom:
                cdx.write_bytes(Path(args.target).read_bytes())
            else:
                run([
                    "sbomnix", args.target, "--require-cpe-dictionary",
                    "--cdx", str(cdx), "--spdx", str(raw / "sbom.spdx.json"),
                    "--csv", str(raw / "sbom.csv"),
                ])
            sbom = json.loads(cdx.read_text())
            if sbom.get("bomFormat") != "CycloneDX":
                raise ValueError("Expected a CycloneDX inventory")
            if "lock_sha256" in metadata and hashlib.sha256(lock.read_bytes()).hexdigest() != metadata["lock_sha256"]:
                raise ValueError("Lockfile changed during inventory generation")

            phase = "refreshing the vulnerability database"
            # An explicit empty config prevents a developer's ignore rules from
            # silently changing the CI/local report. No severity failure gate.
            config = raw / "grype.yaml"
            config.write_text("{}\n")
            grype = ["grype", "--config", str(config)]
            run([*grype, "db", "update"])
            (raw / "database.json").write_text(run([*grype, "db", "status", "-o", "json"]))
            env["GRYPE_DB_AUTO_UPDATE"] = "false"

            phase = "matching vulnerabilities"
            report_path = raw / "vulnerabilities.json"
            run([*grype, "sbom:" + str(cdx), "-o", "json", "--file", str(report_path)])
            report = json.loads(report_path.read_text())
            summary.update(summarize(sbom, report), status="complete")
        except (OSError, ValueError, KeyError, TypeError, RuntimeError):
            failed = True
            summary["failed_phase"] = phase
            # No exception text in the public report: it may name private code.
            with (raw / "scan.log").open("a") as log:
                traceback.print_exc(file=log)
        metadata.update(summary)
        write_json(raw / "metadata.json", metadata)
        # Keep the archive outside raw so it cannot include itself.
        with tempfile.TemporaryDirectory(prefix="nix-security-archive-") as archive_dir:
            archive = Path(archive_dir) / "report.tar.gz"
            with tarfile.open(archive, "w:gz") as bundle:
                for path in sorted(raw.iterdir()):
                    bundle.add(path, arcname=path.name)
            subprocess.run([
                "age", "--recipients-file", str(recipient), "--output",
                str(output / "report.tar.gz.age"), str(archive),
            ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    write_json(output / "summary.json", summary)
    lines = ["### Nix security scan", "", f"Scope: {args.scope}. Status: {summary['status']}.", ""]
    if failed:
        lines.append(f"Could not complete {phase}. This is not a clean scan.")
    else:
        lines.extend([
            f"Inventoried {summary['components']} runtime components; found {summary['findings']} component/advisory matches.",
            "", "| Severity | Matches |", "| --- | ---: |",
            *(f"| {severity} | {summary['severity'][severity]} |" for severity in SEVERITIES),
            "", "Findings are informational and need Nix patch/backport triage; they do not block package updates.",
        ])
    lines.extend(["", "Detailed inventory, findings, database metadata, and logs are in the age-encrypted artifact.", ""])
    markdown = "\n".join(lines)
    (output / "summary.md").write_text(markdown)
    print(markdown)
    if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(summary_path).open("a") as summary_file:
            summary_file.write(markdown)
    return 1 if failed else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", help="Realized Nix output/flakeref, or CycloneDX file with --sbom")
    parser.add_argument("--sbom", action="store_true", help="Rescan a retained CycloneDX inventory")
    parser.add_argument("--scope", choices=("candidate", "committed", "deployed", "inventory"), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--recipients", type=Path, default=Path(".github/security/age-recipients.txt"))
    args = parser.parse_args()
    try:
        return run_scan(args)
    except (OSError, ValueError, subprocess.CalledProcessError):
        print("Security scan setup or encryption failed. No successful assessment was produced.")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
