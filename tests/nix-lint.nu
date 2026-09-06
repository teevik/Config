use std/assert
use test-utils.nu [with-scratch assert-success]

def main [lint: path, fixtures: path] {
    let lint = ($lint | path expand)
    let fixtures = ($fixtures | path expand)
    with-scratch {|scratch|
        mkdir checks hosts/generated modules packages templates tests dotfiles
        cp ($fixtures | path join clean.nix.txt) flake.nix
        cp ($fixtures | path join clean.nix.txt) formatter.nix
        cp ($fixtures | path join parse-error.nix.txt) hosts/generated/hardware.nix
        cp ($fixtures | path join parse-error.nix.txt) dotfiles/ignored.nix
        assert-success (^$lint . | complete)

        let diagnostics = {
            repeated-keys: 'Avoid repeated keys'
            unused-binding: 'Unused let binding'
            parse-error: '(?i)parse|syntax|unexpected|expected'
        }
        for fixture in ($diagnostics | columns) {
            let original = (open --raw ($fixtures | path join $"($fixture).nix.txt"))
            $original | save --force 'packages/new file.nix'
            let result = (^$lint . | complete)
            assert ($result.exit_code != 0) $"Lint accepted ($fixture)"
            assert (($result.stdout + $result.stderr) =~ ($diagnostics | get $fixture)) $"Missing diagnostic: ($result)"
            assert equal (open --raw 'packages/new file.nix') $original
            print $"PASS: rejects ($fixture) without editing files"
        }

        open --raw ($fixtures | path join clean.nix.txt) | save --force 'packages/new file.nix'
        assert-success (^$lint . | complete)
        assert ((^$lint missing-root | complete).exit_code != 0) 'Lint accepted a missing root'
        'let broken = ' | save 'packages/new file.nu'
        let result = (^$lint . | complete)
        assert ($result.exit_code != 0) 'Lint accepted invalid Nushell syntax'
        assert ($result.stderr =~ 'invalid Nushell script')
        assert equal (open --raw 'packages/new file.nu') 'let broken = '
        'def main [] { print "valid" }' | save --force 'packages/new file.nu'
        assert-success (^$lint . | complete)
        print 'PASS: Nu syntax errors fail lint without editing files'
    }
}
