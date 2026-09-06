def --wrapped run-linter [command: string, ...args: string] {
    let result = (^$command ...$args | complete)
    print --no-newline $result.stdout
    print --stderr --no-newline $result.stderr
    $result.exit_code == 0
}

def main [root: path = .] {
    cd $root
    if not ($env.STATIX_CONFIG | path exists) {
        error make {msg: 'Missing pinned Statix configuration'}
    }
    # Include untracked files locally, but never walk dotfiles or dependencies.
    # Keep these source roots aligned with checks/nix-lint.nix.
    mut files = [flake.nix formatter.nix]
    mut scripts = []
    for directory in [checks hosts modules packages templates tests] {
        if not ($directory | path exists) {
            error make {msg: $"Missing source directory: ($directory)"}
        }
        let found = (glob $"($directory)/**/*.nix" --no-dir --no-symlink
            | where {|file| ($file | path relative-to $env.PWD) !~ '^hosts/.*/hardware\.nix$'})
        $files = ($files | append $found)
        $scripts = ($scripts | append (glob $"($directory)/**/*.nu" --no-dir --no-symlink))
    }
    $files = ($files | sort)

    # Run both tools even when one fails. Never apply fixes in this command.
    mut success = true
    for file in $files {
        if not (run-linter statix check --config $env.STATIX_CONFIG $file) {
            $success = false
        }
    }
    if not (run-linter deadnix --fail -- ...$files) {
        $success = false
    }
    for script in ($scripts | sort) {
        let valid = try { nu-check --debug $script } catch {|err|
            print --stderr $err.msg
            false
        }
        if not $valid {
            print --stderr $"FAIL: invalid Nushell script: ($script)"
            $success = false
        }
    }
    if not $success { exit 1 }
    print $"PASS: Statix and deadnix \(($files | length) Nix files; generated hardware excluded\)"
    print $"PASS: Nushell syntax \(($scripts | length) scripts\)"
}
