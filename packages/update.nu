# Export only validated, update-owned files. A fixed sources/ root preserves
# relative paths through artifact upload, even when only package files changed.
# failures.json lists the updates that were left out, for the PR body.
def export-update [root: path, destination: path, files: list<string>, failures: list<record>] {
    let staging = (mktemp --directory --tmpdir-path ($destination | path dirname) .package-update.XXXXXX)
    try {
        for file in $files {
            let target = ($staging | path join sources $file)
            mkdir ($target | path dirname)
            ^cp --preserve=mode -- ($root | path join $file) $target
        }
        $files | str join "\n" | $in + "\n" | save ($staging | path join files.txt)
        $failures | select label error | to json --indent 2 | save ($staging | path join failures.json)
        mv $staging $destination
    } catch {|err|
        rm --recursive --force $staging
        error make {msg: $err.msg}
    }
}

# Run one update script with its output streamed. Returns null on success, or
# the end of its stderr, where Nix and Nu report what went wrong.
def run-step [step: record] {
    print $"Updating ($step.label)"
    let log = (mktemp --tmpdir package-update.XXXXXX)
    try {
        ^$nu.current-exe --no-config-file ('packages' | path join $step.script) ...$step.args
            | tee --stderr { save --force $log }
        rm $log
        null
    } catch {|err|
        let tail = (open --raw $log | ansi strip | lines | last 30 | str join "\n" | str trim)
        rm $log
        let message = if ($tail | is-empty) { $err.msg } else { $tail }
        # Keep the record short enough to quote in a pull request body.
        if ($message | str length) > 4000 { '...' + ($message | str substring (-4000)..) } else { $message }
    }
}

# Refresh every flake input and maintained package, then validate them together.
#
# Each update step leaves its files either fully updated or untouched. A failed
# step skips the rest of its chain; the other chains still run, and whatever
# succeeded is validated (and exported). Exit status:
# - non-zero when every step failed, since nothing was updated;
# - non-zero when validation or export of the successful updates fails;
# - with --export, zero after a partial failure: failures.json carries it;
# - without --export, non-zero after a partial failure, once the successful
#   updates were validated, because the exit status is then the only report.
# Completed edits are kept for inspection and reruns in every case.
def main [
    --no-build # Refresh sources without validation builds.
    --skip-inputs # Reuse flake.lock after an input update already completed.
    --export: path # Write validated files to a new directory for CI handoff.
] {
    let root = ($env.FILE_PWD | path dirname)
    let destination = if $export == null { null } else { $export | path expand }
    if $destination != null {
        if $no_build { error make {msg: 'Export requires validation builds'} }
        if ($destination | path exists) { error make {msg: 'Export directory must not already exist'} }
        if not ($destination | path dirname | path exists) { error make {msg: 'Export parent directory must exist'} }
    }
    let catalog = (open ($env.FILE_PWD | path join update-packages.json))
    # T3 Code builds against the locked llm-agents input, so it waits for the
    # input refresh. Roc only queries release metadata and runs alongside.
    # Each step writes disjoint files: flake.lock, or its catalog package.
    let inputs = if $skip_inputs { [] } else { [{label: 'all flake inputs', script: update-inputs.nu, args: [], package: null}] }
    let chains = [
        ($inputs | append {label: 'T3 Code nightly', script: update-t3code.nu, args: [--no-build], package: t3code-nightly})
        [{label: 'Roc nightly', script: update-roc.nu, args: [], package: roc-nightly}]
    ]
    cd $root
    try {
        let failures = ($chains | par-each --keep-order {|chain|
            $chain | reduce --fold [] {|step, failed|
                if ($failed | is-not-empty) {
                    $failed | append ($step | insert error $"Skipped because ($failed.0.label) failed")
                } else {
                    let error = (run-step $step)
                    if $error == null { [] } else { [($step | insert error $error)] }
                }
            }
        } | flatten)
        let report = ($failures | each {|failure| $"($failure.label): ($failure.error)" } | str join "\n")
        if ($failures | length) == ($chains | flatten | length) {
            error make {msg: $"No update succeeded.\n($report)"}
        }
        let failed_packages = ($failures | each {|failure| $failure.package } | compact)
        let packages = ($catalog | columns | where {|name| $name not-in $failed_packages })
        let lock = if ($failures | any {|failure| $failure.package == null }) { [] } else { [flake.lock] }
        # With every package failed, flake.lock alone is left to the host builds.
        if not $no_build and ($packages | is-not-empty) {
            print 'Validating updated packages'
            ^nix build --no-link --print-build-logs --file packages/nu-scripts/update-targets.nix ...$packages
        }
        if $destination != null {
            export-update $root $destination ($lock | append ($packages | each {|name| $catalog | get $name }) | uniq | sort) $failures
        }
        if ($failures | is-not-empty) {
            print --stderr $"Some updates failed and were left out:\n($report)"
            if $destination == null { error make {msg: $"Some updates failed.\n($report)"} }
        }
    } catch {|err|
        error make {msg: $"Package update failed; completed edits were kept.\n($err.msg)"}
    }
    print (if $no_build { 'Package sources updated; validation builds skipped' } else { 'Package update validated' })
}
