"""Check the nightly update pull request body and failure warnings."""

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("pr_body", ROOT / ".github/ci/pr-body.py")
body = importlib.util.module_from_spec(spec)
spec.loader.exec_module(body)

RUN = "https://github.com/owner/repo/actions/runs/1"


def lock(**revs):
    nodes = {"root": {"inputs": {name: name for name in revs}}}
    nodes.update({name: {"locked": {"type": "github", "rev": rev}} for name, rev in revs.items()})
    return {"version": 7, "root": "root", "nodes": nodes}


class PullRequestBodyTests(unittest.TestCase):
    def test_changed_added_and_removed_inputs_render_as_rows(self):
        old = lock(changed="aaa", removed="bbb", same="ccc")
        new = lock(added="ddd", changed="eee", same="ccc")
        text = body.render(old, new, [], RUN)
        self.assertIn(
            "| Input | Old revision | New revision |\n"
            "| --- | --- | --- |\n"
            "| `added` | `not present` | `ddd` |\n"
            "| `changed` | `aaa` | `eee` |\n"
            "| `removed` | `bbb` | `not present` |\n",
            text,
        )
        self.assertNotIn("`same`", text)
        self.assertIn(f"\nRun: {RUN}\n", text)

    def test_no_changes_render_placeholder_row(self):
        text = body.render(lock(nixpkgs="aaa"), lock(nixpkgs="aaa"), [], RUN)
        self.assertTrue(text.endswith("| --- | --- | --- |\n| _No locked inputs changed_ | — | — |\n"))

    def test_no_failures_render_no_section(self):
        self.assertNotIn("Failed updates", body.render(lock(), lock(), [], RUN))

    def test_error_fence_is_longer_than_any_backtick_run(self):
        failures = [{"label": "pkg", "error": "a ``` b ```` c"}, {"label": "other", "error": "plain"}]
        text = body.render(lock(), lock(), failures, RUN)
        self.assertIn(
            "### Failed updates\n\n"
            "These updates failed and are not part of this pull request. Their files were left unchanged.\n\n"
            "**pkg**\n\n`````text\na ``` b ```` c\n`````\n\n"
            "**other**\n\n```text\nplain\n```\n",
            text,
        )
        self.assertTrue(text.endswith("```\n"))

    def test_warnings_escape_workflow_commands(self):
        failures = [{"label": "pkg", "error": "100%\r\n::error::injected\n"}]
        self.assertEqual(body.warnings(failures), [
            "::warning title=Nightly update failed::pkg: 100%25%0D%0A::error::injected%0A",
        ])


if __name__ == "__main__":
    unittest.main()
