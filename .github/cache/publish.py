"""Sign, copy, retain and verify an entire NixOS runtime closure privately."""

from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
from urllib.parse import urljoin, urlparse
from urllib.error import HTTPError
from urllib.request import Request, urlopen


HOST = "homelab.tail84b6c.ts.net"
CACHE = f"http://{HOST}:8501"
DESTINATION = f"nix-cache@{HOST}"


def run(*args, env=None):
    return subprocess.check_output(args, text=True, env=env).strip()


def closure_info(path):
    info = json.loads(run("nix", "path-info", "--recursive", "--json", path))
    if isinstance(info, list):
        info = {entry["path"]: entry for entry in info}
    if not info or any(value is None for value in info.values()):
        raise ValueError("The system closure is incomplete")
    return info


def closure_digest(paths):
    return hashlib.sha256("".join(path + "\n" for path in sorted(paths)).encode()).hexdigest()


def check_cached(path):
    try:
        check_cached_response(path)
    except HTTPError as error:
        error.close()
        raise


def check_cached_response(path):
    digest = Path(path).name.split("-", 1)[0]
    # Bypass any earlier HTTP negative cache entry. Nix's own negative cache is
    # not involved in this publication check.
    with urlopen(f"{CACHE}/{digest}.narinfo?publication=1", timeout=60) as response:
        fields = {}
        for line in response.read().decode().splitlines():
            key, _, value = line.partition(": ")
            fields.setdefault(key, []).append(value)
    if fields.get("StorePath") != [path] or not fields.get("Sig") or not fields.get("URL"):
        raise ValueError("Cache returned missing or invalid signed metadata")
    nar_url = urljoin(CACHE + "/", fields["URL"][0])
    # The proxy should always normalize NAR URLs to itself.
    if (urlparse(nar_url).scheme, urlparse(nar_url).netloc) != (urlparse(CACHE).scheme, urlparse(CACHE).netloc):
        raise ValueError("Cache returned an unexpected archive origin")
    with urlopen(Request(nar_url, method="HEAD"), timeout=60) as response:
        if response.status != 200:
            raise ValueError("Cached archive is unavailable")


def publish(host, generation, path):
    if host not in {"desktop", "zenbook"}:
        raise ValueError("Unsupported host")
    path = str(Path(path).resolve())
    info = closure_info(path)
    nar_bytes = sum(item["narSize"] for item in info.values())
    with tempfile.TemporaryDirectory(prefix="nix-cache-credentials-") as temporary:
        work = Path(temporary)
        identity = work / "ssh-key"
        signing_key = work / "signing-key"
        for file, variable in [(identity, "NIX_CACHE_SSH_KEY"), (signing_key, "NIX_CACHE_SIGNING_KEY")]:
            value = os.environ.get(variable, "")
            if not value.strip():
                raise ValueError(f"Missing {variable}")
            file.write_text(value.rstrip() + "\n")
            file.chmod(0o600)
        ssh_options = [
            "-p", "2224", "-i", str(identity),
            "-o", "IdentityAgent=none", "-o", "IdentitiesOnly=yes",
            "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
            "-o", f"UserKnownHostsFile={Path(__file__).with_name('known_hosts')}",
            "-o", "ConnectTimeout=15",
        ]
        env = dict(os.environ, NIX_SSHOPTS=shlex.join(ssh_options))
        # Do not pass GitHub's secret environment variables to child processes.
        env.pop("NIX_CACHE_SSH_KEY", None)
        env.pop("NIX_CACHE_SIGNING_KEY", None)
        run("ssh", *ssh_options, DESTINATION, f"cache-preflight {nar_bytes}", env=env)
        subprocess.run(["nix", "store", "sign", "--recursive", "--key-file", str(signing_key), path],
                       check=True, env=env)
        subprocess.run(["nix", "copy", "--to", f"ssh://{DESTINATION}",
                        "--substitute-on-destination", path], check=True, env=env)
        command = shlex.join(["cache-publish", host, generation, path])
        receipt = json.loads(run("ssh", *ssh_options, DESTINATION, command, env=env))
        if receipt.get("closureDigest") != closure_digest(info) or receipt.get("closurePaths") != len(info):
            raise ValueError("The retained remote closure differs from the built system")
        public_key = Path(__file__).resolve().parents[2] / "modules/nixos/minimal/homelab-cache.pub"
        subprocess.run([
            "nix", "store", "verify", "--store", CACHE, "--recursive", "--no-contents",
            "--sigs-needed", "1", "--option", "extra-trusted-public-keys", public_key.read_text().strip(), path,
        ], check=True, env=env)
        with ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(check_cached, info))
        print(f"Retained and verified {host}: {len(info)} paths, {nar_bytes / 1024**3:.1f} GiB")
        if receipt.get("overBudget"):
            print("::warning::Homelab retained closures exceed the 500 GiB operating budget")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("Usage: publish.py HOST GENERATION SYSTEM_PATH")
    publish(*sys.argv[1:])
