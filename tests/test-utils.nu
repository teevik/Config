# Keep scratch directories private and clean them on success or ordinary errors.
# Commands under test run in child processes so exit does not bypass cleanup.
export def with-scratch [test: closure] {
    let scratch = (mktemp --directory --tmpdir config-tests.XXXXXX)
    try {
        do { cd $scratch; do $test $scratch }
    } catch {|err|
        rm --recursive --force $scratch
        error make {msg: $err.msg}
    }
    rm --recursive --force $scratch
}

export def assert-success [result: record] {
    if $result.exit_code != 0 {
        error make {msg: $"Command failed with ($result.exit_code):\n($result.stdout)\n($result.stderr)"}
    }
}

# Mirrors fixture-hash in nu-fixtures/command.nu, the offline Nix model.
export def fixture-hash [text: string] {
    'sha256-' + ($text | hash sha256 --binary | encode base64)
}

# A fake T3 Code source tree served by the offline Nix model.
export def t3-source [root: path, version: string, lock: string, licenses: string] {
    let source = ($root | path join sources $version)
    mkdir ($source | path join scripts/lib)
    $lock | save --force ($source | path join pnpm-lock.yaml)
    $licenses | save --force ($source | path join third-party-licenses.config.json)
    'export {}' | save --force ($source | path join scripts/lib/third-party-licenses.ts)
}

# `git ls-remote --tags --refs` output for the given tags.
export def t3-tags [tags: list<string>] {
    $tags | each {|tag| $"($tag | hash sha256 | str substring 0..39)\trefs/tags/($tag)" } | str join "\n"
}
