"""Exercise the stowed Nushell wrapper without loading personal configuration."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "dotfiles/.config/nushell/config.nu").read_text()
start = source.index("def with-clean-term ")
WRAPPER = source[start:source.index("@complete external", start)]


class TerminalWrapperTests(unittest.TestCase):
    def run_wrapper(self, code, *, socket=True, available=True, missing=False):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            kitty = work / "kitty"
            kitty.write_text(
                f"#!{sys.executable}\n"
                "import json, os, sys\n"
                "with open(os.environ['KITTY_LOG'], 'a') as log:\n"
                "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
                "sys.exit(int(os.environ['KITTY_PROBE_CODE']) if sys.argv[1:] == ['@', 'ls'] else 0)\n"
            )
            kitty.chmod(0o755)
            command = work / "command.py"
            command.write_text(
                "import sys\n"
                "print(sys.argv[1])\n"
                "print('diagnostic', file=sys.stderr)\n"
                f"sys.exit({code})\n"
            )
            args = ["missing-review-command"] if missing else [sys.executable, str(command), "a space"]
            program = work / "test.nu"
            program.write_text(
                WRAPPER + "\nwith-clean-term " + " ".join(json.dumps(arg) for arg in args)
                + '\nprint "continued"\n'
            )
            env = dict(os.environ, PATH=str(work) + os.pathsep + os.environ["PATH"],
                       KITTY_LOG=str(work / "kitty.log"), KITTY_PROBE_CODE="0" if available else "1")
            env.pop("KITTY_LISTEN_ON", None)
            if socket:
                env["KITTY_LISTEN_ON"] = "review-test"
            result = subprocess.run(["nu", "--no-config-file", str(program)],
                                    env=env, text=True, capture_output=True, timeout=10)
            log = work / "kitty.log"
            calls = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            return result, calls

    def test_restores_terminal_and_preserves_command_result(self):
        for code in [0, 7]:
            with self.subTest(code=code):
                result, calls = self.run_wrapper(code)
                self.assertEqual(result.returncode, code)
                self.assertIn("a space", result.stdout)
                self.assertIn("diagnostic", result.stderr)
                self.assertEqual("continued" in result.stdout, code == 0)
                self.assertEqual(calls, [
                    ["@", "ls"], ["@", "set-spacing", "padding=0"],
                    ["@", "set-background-opacity", "1"],
                    ["@", "set-spacing", "padding=default"],
                    ["@", "set-background-opacity", "0.5"],
                ])

    def test_without_kitty_preserves_failure(self):
        for socket, available in [(False, True), (True, False)]:
            with self.subTest(socket=socket, available=available):
                result, calls = self.run_wrapper(7, socket=socket, available=available)
                self.assertEqual(result.returncode, 7)
                self.assertNotIn("continued", result.stdout)
                self.assertEqual(calls, [["@", "ls"]] if socket else [])

    def test_restores_terminal_when_command_is_missing(self):
        result, calls = self.run_wrapper(0, missing=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("continued", result.stdout)
        self.assertEqual(calls[-2:], [["@", "set-spacing", "padding=default"],
                                     ["@", "set-background-opacity", "0.5"]])


if __name__ == "__main__":
    unittest.main()
