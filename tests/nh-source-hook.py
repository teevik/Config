#!/usr/bin/env python3
"""Exercise the patched nh CLI with recording commands; no builds or activation.

Usage: python3 tests/nh-source-hook.py /path/to/patched/nh [CONFIGURED_NH CONFIG_ROOT]
"""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def executable(path, body):
    path.write_text(f"#!{sys.executable}\n{body}")
    path.chmod(0o700)
    return str(path)


nh = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory(prefix="nh-source-hook-test-") as temporary:
    root = Path(temporary)
    checkout = root / "working tree"
    checkout.mkdir()
    (checkout / "flake.nix").write_text("{ outputs = _: {}; }\n")
    log = root / "events.jsonl"
    common = """
import json, os, sys
from pathlib import Path
with open(os.environ['NH_TEST_LOG'], 'a') as log:
    log.write(json.dumps([Path(sys.argv[0]).name, sys.argv[1:]]) + '\\n')
"""
    executable(root / "nix", common + """
if sys.argv[1:3] == ['flake', 'update']:
    Path(os.environ['NH_TEST_CHECKOUT'], 'flake.lock').write_text('updated')
elif sys.argv[1:2] != ['build']:
    if sys.argv[1:] == ['eval', '--impure', '--raw', '--file',
                        str(Path(os.environ['NH_TEST_CONFIG_ROOT'],
                                 'modules/nixos/minimal/source-snapshot.nix'))]:
        print('/nix/store/prepared-source')
    else:
        raise SystemExit('Unexpected Nix command')
""")
    hook = executable(root / "prepare source", common + """
if os.environ.get('NH_TEST_EXPECT_UPDATE'):
    assert Path(os.environ['NH_TEST_CHECKOUT'], 'flake.lock').read_text() == 'updated'
print('path:/nix/store/prepared-source')
if os.environ.get('NH_TEST_FAIL'):
    raise SystemExit(1)
""")
    env = os.environ.copy()
    for key in ("FLAKE", "NH_FLAKE", "NH_OS_FLAKE", "NH_FILE", "NH_ATTRP",
                "NH_OS_FLAKE_SOURCE_COMMAND"):
        env.pop(key, None)
    env.update(PATH=f"{root}:{env['PATH']}", NH_NO_CHECKS="1",
               NH_TEST_LOG=str(log), NH_TEST_CHECKOUT=str(checkout))
    base = [nh, "--elevation-strategy", "none", "os", "build",
            "--no-nom", "--diff", "never", "-H", "host.with.dot"]
    attribute = '#nixosConfigurations."host.with.dot".config.system.build.toplevel'

    def run(arguments, extra_env=None, success=True):
        log.write_text("")
        result = subprocess.run(base + arguments, cwd=root,
                                env=env | (extra_env or {}),
                                capture_output=True, text=True, timeout=30)
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return [json.loads(line) for line in log.read_text().splitlines()]

    for update in ([], ["--update"], ["--update-input", "nixpkgs"]):
        events = run([str(checkout), "--flake-source-command", hook] + update,
                     {"NH_TEST_EXPECT_UPDATE": "1"} if update else {})
        assert [event[0] for event in events] == (
            ["nix", "prepare source", "nix"] if update else ["prepare source", "nix"]
        ), events
        assert events[-2][1] == [str(checkout)], events
        assert "path:/nix/store/prepared-source" + attribute in events[-1][1], events
        if update:
            assert events[0][1][-2:] == ["--flake", str(checkout)], events

    # Native environment-variable defaults and explicit attribute selection.
    events = run([], {"NH_OS_FLAKE": str(checkout) + '#"selected.host"',
                      "NH_OS_FLAKE_SOURCE_COMMAND": hook})
    assert events[0] == ["prepare source", [str(checkout)]], events
    assert ('path:/nix/store/prepared-source#nixosConfigurations."selected.host"'
            '.config.system.build.toplevel') in events[-1][1], events

    # A failed helper must prevent the build, even when it printed a reference.
    events = run([str(checkout), "--flake-source-command", hook],
                 {"NH_TEST_FAIL": "1"}, success=False)
    assert [event[0] for event in events] == ["prepare source"], events

    # Explicit legacy expressions bypass the configured hook.
    events = run(["--expr", "{}", "--flake-source-command", hook])
    assert [event[0] for event in events] == ["nix"], events
    assert "--expr" in events[0][1], events

    # Without a hook, nh must keep the original source reference.
    events = run([str(checkout)])
    assert [event[0] for event in events] == ["nix"], events
    assert str(checkout) + attribute in events[0][1], events

    if len(sys.argv) > 2:
        base[0] = str(Path(sys.argv[2]).resolve())
        config_root = Path(sys.argv[3])
        env['NH_TEST_CONFIG_ROOT'] = str(checkout)
        stale_env = {"NH_OS_FLAKE_SOURCE_COMMAND": str(root / "deleted-hook")}
        config_root.symlink_to(checkout, target_is_directory=True)
        try:
            # The installed package owns its helper, even in a stale login session.
            events = run([str(config_root)], stale_env)
            assert [event[0] for event in events] == ["nix", "nix"], events
            assert events[0][1][0] == "eval", events
            assert "path:/nix/store/prepared-source" + attribute in events[-1][1], events

            # Other checkouts pass through without snapshot evaluation.
            other = root / "other checkout"
            other.mkdir()
            (other / "flake.nix").write_text("{ outputs = _: {}; }\n")
            events = run([str(other)], stale_env)
            assert [event[0] for event in events] == ["nix"], events
            assert str(other) + attribute in events[0][1], events

            # An explicit CLI hook still overrides the packaged default.
            events = run([str(checkout), "--flake-source-command", hook], stale_env)
            assert [event[0] for event in events] == ["prepare source", "nix"], events
        finally:
            config_root.unlink()
        print("PASS: packaged helper (stale environment, other checkout, CLI override)")

print("PASS: 7 nh CLI cases (updates, arguments, defaults, failure, legacy, no hook)")
