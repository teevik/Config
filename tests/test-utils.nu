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
