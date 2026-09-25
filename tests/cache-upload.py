"""Exercise complete-closure publication and actual HTTP cache verification."""

from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import threading
import tempfile
import sys
import subprocess
from types import SimpleNamespace
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("upload", ROOT / ".github/cache/publish.py")
upload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upload)
sys.path.insert(0, str(ROOT / ".github/cache"))
import build as cache_build
import record as cache_record
import seed as cache_seed
SYSTEM = "/nix/store/" + "0" * 32 + "-nixos-system-desktop-test"
MANUAL = "/nix/store/" + "1" * 32 + "-nix-man"
PRIVATE = "/nix/store/" + "2" * 32 + "-marble"


@contextmanager
def cache_server(metadata, archive_status=200):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.end_headers()
            self.wfile.write(metadata.encode())

        def do_HEAD(self):
            self.send_response(archive_status)
            self.end_headers()

        def log_message(self, *_args):
            pass

    with ThreadingHTTPServer(("127.0.0.1", 0), Handler) as server:
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with patch.object(upload, "CACHE", f"http://127.0.0.1:{server.server_port}"):
                yield
        finally:
            server.shutdown()
            thread.join()


class UploadTests(unittest.TestCase):
    def test_signed_metadata_and_archive_are_required(self):
        good = f"StorePath: {SYSTEM}\nSig: cache-1:example\nURL: nar/system.nar.zst\n"
        with cache_server(good):
            upload.check_cached(SYSTEM)
        for bad in [good.replace("Sig: cache-1:example\n", ""), good.replace(SYSTEM, MANUAL),
                    good.replace("nar/system.nar.zst", "http://unexpected.example/nar")]:
            with self.subTest(metadata=bad), cache_server(bad), self.assertRaises(ValueError):
                upload.check_cached(SYSTEM)
        with cache_server(good, 404), self.assertRaises(Exception):
            upload.check_cached(SYSTEM)

    def test_publication_includes_manuals_and_private_runtime_dependencies(self):
        info = {path: {"narSize": 100} for path in [SYSTEM, MANUAL, PRIVATE]}
        receipt = {"closureDigest": upload.closure_digest(info), "closurePaths": 3}
        events = []

        def run(*args, env=None):
            self.assertNotIn("NIX_CACHE_SSH_KEY", env)
            self.assertNotIn("NIX_CACHE_SIGNING_KEY", env)
            events.append(args[-1].split()[0])
            return json.dumps(receipt)

        def execute(args, **kwargs):
            events.append(" ".join(args[:2]))

        with patch.object(upload, "closure_info", return_value=info), \
             patch.object(upload, "run", side_effect=run), \
             patch.object(upload.subprocess, "run", side_effect=execute), \
             patch.object(upload, "check_cached") as verify, \
             patch.dict(os.environ, NIX_CACHE_SSH_KEY="test-key", NIX_CACHE_SIGNING_KEY="test-key"):
            upload.publish("desktop", "123-1", SYSTEM)
        self.assertEqual(events, ["cache-preflight", "nix store", "nix copy", "cache-publish", "nix store"])
        self.assertEqual({call.args[0] for call in verify.call_args_list}, set(info))

    def test_mismatched_remote_closure_fails_publication(self):
        with patch.object(upload, "closure_info", return_value={SYSTEM: {"narSize": 1}}), \
             patch.object(upload, "run", return_value='{"closureDigest":"wrong","closurePaths":1}'), \
             patch.object(upload.subprocess, "run"), \
             patch.object(upload, "check_cached") as verify, \
             patch.dict(os.environ, NIX_CACHE_SSH_KEY="test-key", NIX_CACHE_SIGNING_KEY="test-key"):
            with self.assertRaises(ValueError):
                upload.publish("desktop", "123-1", SYSTEM)
        verify.assert_not_called()

    def test_dependency_manifest_is_rooted_and_verified_without_exposing_credentials(self):
        info = {path: {"narSize": 100} for path in [MANUAL, PRIVATE]}
        receipt = {"closureDigest": upload.closure_digest(info), "closurePaths": 2}
        requests = []

        def run(*args, env=None, input=None):
            self.assertNotIn("NIX_CACHE_SSH_KEY", env)
            requests.append((args, input))
            return json.dumps(info if args[:2] == ("nix", "path-info") else receipt)

        with patch.object(upload, "run", side_effect=run), \
             patch.object(upload.subprocess, "run") as execute, \
             patch.dict(os.environ, NIX_CACHE_SSH_KEY="test-key", NIX_CACHE_SIGNING_KEY="test-key"):
            upload.publish_dependencies("bootstrap", "123-1", [MANUAL, PRIVATE, MANUAL])
        self.assertEqual(json.loads(requests[-1][1]), sorted(info))
        self.assertIn("cache-retain bootstrap 123-1", requests[-1][0])
        self.assertEqual(execute.call_count, 3)
        self.assertIn("--sigs-needed", execute.call_args.args[0])

    def test_failed_upload_retries_completed_outputs_when_build_finishes(self):
        with tempfile.TemporaryDirectory() as temporary:
            roots = Path(temporary)
            cache_record.record(roots, [MANUAL, PRIVATE])
            stop, errors = threading.Event(), []
            calls = []

            def publish(group, generation, paths, **kwargs):
                calls.append(paths)
                if len(calls) == 1:
                    stop.set()  # The compilation has failed/ended during upload.
                    raise ValueError("temporary cache outage")

            with patch.object(cache_build, "publish_dependencies", side_effect=publish):
                cache_build.upload_loop(roots, "desktop", "123-1", stop, errors, interval=0)
            self.assertEqual(calls, [sorted([MANUAL, PRIVATE])] * 2)
            self.assertEqual(errors, [])

    def test_overlapping_batches_verify_each_path_once_and_retry_failures(self):
        verified = set()
        checked = []
        fail = False
        info = {}

        def run(*args, **kwargs):
            if args[:2] == ("nix", "path-info"):
                return json.dumps(info)
            return json.dumps({"closureDigest": upload.closure_digest(info), "closurePaths": len(info)})

        def execute(args, **kwargs):
            if args[:3] == ["nix", "store", "verify"]:
                self.assertNotIn("--recursive", args)
                checked.append(set(kwargs["input"].splitlines()))
                if fail:
                    raise subprocess.CalledProcessError(1, args)

        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(upload, "run", side_effect=run), \
             patch.object(upload.subprocess, "run", side_effect=execute), \
             patch.dict(os.environ, NIX_CACHE_SSH_KEY="test", NIX_CACHE_SIGNING_KEY="test",
                        NIX_CACHE_VERIFIED_PATHS=str(Path(temporary) / "verified.json")):
            info = {path: {"narSize": 1} for path in [MANUAL, SYSTEM]}
            upload.publish_dependencies("desktop", "123-1", [MANUAL], verified=verified)
            self.assertEqual(verified, {MANUAL, SYSTEM})
            info = {path: {"narSize": 1} for path in [PRIVATE, SYSTEM]}
            fail = True
            with self.assertRaises(subprocess.CalledProcessError):
                upload.publish_dependencies("desktop", "123-1", [PRIVATE], verified=verified)
            self.assertEqual(verified, {MANUAL, SYSTEM})
            fail = False
            upload.publish_dependencies("desktop", "123-1", [PRIVATE], verified=verified)
            verified.clear()  # A later step in the same job starts a fresh process.
            upload.publish_dependencies("desktop", "123-1", [PRIVATE], verified=verified)
        self.assertEqual(checked, [{MANUAL, SYSTEM}, {PRIVATE}, {PRIVATE}])
        self.assertEqual(verified, {MANUAL, PRIVATE, SYSTEM})

    def test_failed_build_still_publishes_outputs_and_returns_original_failure(self):
        real_run = subprocess.run
        child = '''
import os, subprocess, sys
assert "NIX_CACHE_SSH_KEY" not in os.environ
assert "NIX_CACHE_SIGNING_KEY" not in os.environ
hook = os.environ["NIX_CONFIG"].split("post-build-hook = ", 1)[1].strip()
subprocess.run([hook], check=True, env=dict(os.environ, OUT_PATHS=sys.argv[1]))
sys.exit(7)
'''

        def execute(args, **kwargs):
            if args[:2] == ["sudo", "install"]:
                Path(args[-1]).mkdir()
                return SimpleNamespace(returncode=0)
            if args[:2] == ["sudo", "rmdir"]:
                Path(args[-1]).rmdir()
                return SimpleNamespace(returncode=0)
            return real_run(args, **kwargs)

        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(cache_build, "GCROOTS", Path(temporary)), \
             patch.object(cache_build.subprocess, "run", side_effect=execute), \
             patch.object(cache_build, "publish_dependencies") as publish, \
             patch.dict(os.environ, NIX_CACHE_SSH_KEY="private", NIX_CACHE_SIGNING_KEY="private"):
            result = cache_build.run("desktop", "123-1", [sys.executable, "-c", child, MANUAL + " " + PRIVATE])
            self.assertEqual(result, 7)
            publish.assert_called_once_with("desktop", "123-1", sorted([MANUAL, PRIVATE]), verified=set())
            self.assertEqual(list(Path(temporary).iterdir()), [])

    def test_seeding_queries_existing_outputs_without_realising_them(self):
        with patch.object(cache_seed.subprocess, "check_output", return_value=f"{MANUAL}\n{PRIVATE}.drv\n{PRIVATE}\n") as query, \
             patch.object(cache_seed.Path, "exists", side_effect=lambda: True):
            outputs = cache_seed.existing_outputs([SYSTEM + ".drv"])
        self.assertEqual(outputs, sorted([MANUAL, PRIVATE]))
        self.assertIn("--include-outputs", query.call_args.args[0])
        self.assertNotIn("--realise", query.call_args.args[0])


if __name__ == "__main__":
    unittest.main()
