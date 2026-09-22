"""Exercise complete-closure publication and actual HTTP cache verification."""

from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
import json
import os
from pathlib import Path
import threading
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("upload", ROOT / ".github/cache/publish.py")
upload = importlib.util.module_from_spec(spec)
spec.loader.exec_module(upload)
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


if __name__ == "__main__":
    unittest.main()
