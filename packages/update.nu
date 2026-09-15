# Export only validated, update-owned files. A fixed sources/ root preserves
# relative paths through artifact upload, even when only package files changed.
def export-update [root: path, destination: path, files: list<string>] {
    let staging = (mktemp --directory --tmpdir-path ($destination | path dirname) .package-update.XXXXXX)
    try {
        for file in $files {
            let target = ($staging | path join sources $file)
            mkdir ($target | path dirname)
            ^cp --preserve=mode -- ($root | path join $file) $target
        }
        $files | str join "\n" | $in + "\n" | save ($staging | path join files.txt)
        mv $staging $destination
    } catch {|err|
        rm --recursive --force $staging
        error make {msg: $err.msg}
    }
}

# Refresh every flake input and maintained package, then validate them together.
# Failures stop the workflow and retain completed edits for inspection/reruns.
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
    cd $root
    try {
        if not $skip_inputs {
            print 'Updating all flake inputs'
            ^$nu.current-exe --no-config-file packages/update-inputs.nu
        }
        print 'Updating OpenCode CLI and desktop'
        ^$nu.current-exe --no-config-file packages/update-opencode.nu
        print 'Updating T3 Code nightly'
        ^$nu.current-exe --no-config-file packages/update-t3code.nu --no-build
        if not $no_build {
            print 'Validating updated packages'
            ^nix build --no-link --print-build-logs --file packages/update-targets.nix ...($catalog | columns)
        }
        if $destination != null {
            export-update $root $destination ($catalog | values | uniq | sort)
        }
    } catch {|err|
        error make {msg: $"Package update failed; completed edits were kept.\n($err.msg)"}
    }
    print (if $no_build { 'Package sources updated; validation builds skipped' } else { 'Package update validated' })
}
