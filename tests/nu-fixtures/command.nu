# Offline command double: never contacts a network or calls a real Nix daemon.
use std/assert

# Fixture hashes are derived from content, like real fixed-output hashes, so
# unchanged inputs keep both their hash and their fake store path.
def fixture-hash [text: string] {
    'sha256-' + ($text | hash sha256 --binary | encode base64)
}

def t3-file [args: list<string>] {
    let index = ($args | enumerate | where item == --file | first).index
    ($args | get ($index + 1) | path dirname | path dirname | path join t3code-nightly.nix)
}

# Version and hashes as currently declared in the T3 Code definition.
def t3-declared [file: path] {
    let source = (open --raw $file)
    let field = {|pattern| ($source | parse --regex $pattern | first).hash }
    {
        version: ($source | parse --regex 'version = "(?<version>[^"]+)";' | first).version
        src: (do $field '(?s)fetchFromGitHub \{.*?hash = "(?<hash>[^"]+)"')
        licenseNotices: (do $field '(?s)licenseNotices = .*?outputHash = "(?<hash>[^"]+)"')
        pnpmDeps: (do $field '(?s)fetchPnpmDeps \{.*?hash = "(?<hash>[^"]+)"')
    }
}

# MOCK_FAILURE names one failure, or several separated by commas.
def failing [name: string] {
    $name in ($env.MOCK_FAILURE? | default '' | split row ',')
}

# Fail like a real command: report on stderr, then exit non-zero.
def fail [name: string] {
    print --stderr $"error: mock ($name) failure"
    exit 17
}

def t3-source [version: string] { $env.MOCK_T3 | path join sources $version }

# The hash each input really has for a fixture source tree.
def t3-expected [attr: string, version: string] {
    let source = (t3-source $version)
    match $attr {
        src => (fixture-hash $"src:($version)")
        pnpmDeps => (fixture-hash ('pnpmDeps:' + (open --raw ($source | path join pnpm-lock.yaml))))
        licenseNotices => (fixture-hash ('licenseNotices:' + (open --raw ($source | path join third-party-licenses.config.json))))
    }
}

def t3-output [attr: string, hash: string] {
    $env.MOCK_T3 | path join store $"($attr)-($hash | hash sha256)"
}

def t3-out-path [declared: record, attr: string] {
    let hash = ($declared | get $attr)
    if $attr == src {
        # Only a correctly declared source resolves to the fixture tree.
        if $hash == (t3-expected src $declared.version) { t3-source $declared.version } else { t3-output src $hash }
    } else {
        t3-output $attr $hash
    }
}

# Model Nix for the T3 Code updater's evaluations and dependency builds;
# returns false for other commands, including validation builds.
def t3-nix [args: list<string>] {
    if not ($args | any {|arg| $arg =~ '^t3code-nightly($|\.)' }) { return false }
    if $args.0 == 'build' and '--keep-going' not-in $args { return false }
    let declared = (t3-declared (t3-file $args))
    match $args.0 {
        'eval' => {
            let apply = ($args | last)
            if $apply == 't3code-nightly.src.outPath' {
                print --no-newline (t3-out-path $declared src)
            } else if ($apply | str contains srcPath) {
                {
                    version: $declared.version
                    srcPath: (t3-out-path $declared src)
                    hashes: ($declared | select src pnpmDeps licenseNotices)
                } | to json | print
            } else {
                let attrs = ($apply | parse --regex '"(?<attr>[A-Za-z]+)"' | get attr)
                $attrs | each {|attr| t3-out-path $declared $attr } | to json | print
            }
        }
        'build' => {
            mut failed = false
            for attr in ($args | where {|arg| $arg starts-with 't3code-nightly.' } | each { str replace 't3code-nightly.' '' }) {
                let declared_hash = ($declared | get $attr)
                if ((t3-out-path $declared $attr) | path exists) { continue }
                {tool: fetch, args: [$attr]} | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
                if (failing fetch) {
                    print --stderr $"error: builder for ($attr) failed"
                    $failed = true
                    continue
                }
                let actual = (t3-expected $attr $declared.version)
                mkdir (if $attr == src { t3-source $declared.version } else { t3-output $attr $actual })
                if $actual != $declared_hash {
                    print --stderr $"error: hash mismatch in fixed-output derivation '($attr).drv':\n         specified: ($declared_hash)\n            got:    ($actual)"
                    $failed = true
                }
            }
            if $failed { exit 1 }
        }
        _ => { error make {msg: $"Unexpected T3 Code Nix command: ($args)"} }
    }
    true
}

def git-command [args: list<string>] {
    assert equal ($args | first 3) [ls-remote --tags --refs]
    assert equal ($args | skip 3) [https://github.com/pingdotgg/t3code 'v*-nightly.*']
    print ($env.MOCK_TAGS? | default '')
}

# Model command effects in a writable checkout; production update scripts still
# perform their real fetching, parsing, replacement, sequencing, and export.
def update-command [tool: string, args: list<string>] {
    let release_mode = ($env.MOCK_RELEASE? | default 'valid')
    if (failing $tool) { fail $tool }
    match $tool {
        'nix' => {
            if (t3-nix $args) { return }
            if $args.0 == 'eval' {
                # Exercise the native fallback here; the parallel path is
                # checked against real Nix in tests/update-inputs.py.
                print '[]'
            } else if $args == [flake update] {
                if (failing flake) { fail flake }
                {fixture: updated} | to json | save --force flake.lock
            } else if $args.0 == 'build' {
                # Validation sees every requested package already updated;
                # T3 Code also needs the refreshed lock it was built against.
                if roc-nightly in $args {
                    assert (open --raw packages/roc-nightly.nix | str contains '2026-10-01-abcdef0')
                }
                if t3code-nightly in $args {
                    assert (open --raw packages/t3code-nightly.nix | str contains '0.0.99-nightly.20261001.42')
                    assert equal (open --raw flake.lock | from json).fixture updated
                }
                if (failing build) { fail build }
            } else { error make {msg: $"Unexpected Nix command: ($args)"} }
        }
        'git' => { git-command $args }
        'curl' => {
            let url = ($args | last)
            assert equal $url 'https://api.github.com/repos/roc-lang/nightlies/releases/latest'
            if $release_mode == 'require-auth' {
                let input = if '@-' in $args { ^cat } else { '' }
                if '--header' not-in $args or '@-' not-in $args or ($input | default '' | str trim) != 'Authorization: Bearer fixture-read-only-token' {
                    print --stderr 'curl: (22) The requested URL returned error: 403'
                    exit 22
                }
            }
            if $release_mode == 'roc-invalid-json' { print 'not JSON'; return }
            mut release = {
                tag_name: nightly-2026-10-01-abcdef0
                assets: [
                    {name: roc_nightly-linux_x86_64-2026-10-01-abcdef0.tar.gz, digest: ('sha256:' + ('x64' | hash sha256))}
                    {name: roc_nightly-linux_arm64-2026-10-01-abcdef0.tar.gz, digest: ('sha256:' + ('arm64' | hash sha256))}
                ]
            }
            if $release_mode == 'roc-invalid-tag' { $release = ($release | update tag_name 'alpha4-rolling') }
            if $release_mode == 'roc-missing-arm64' { $release = ($release | update assets ($release.assets | first 1)) }
            if $release_mode == 'roc-invalid-digest' { $release = ($release | update assets.1.digest 'sha256:bad') }
            if $release_mode == 'roc-missing-digest' { $release = ($release | reject assets.1.digest) }
            if $release_mode == 'roc-duplicate-asset' { $release = ($release | update assets ($release.assets | append $release.assets.0)) }
            $release | to json | print
        }
        _ => { error make {msg: $"Unexpected update tool: ($tool)"} }
    }
}

def --wrapped main [...raw_args] {
    # Nu parses bare CLI false/true/numbers as values in wrapped rest arguments.
    let args = ($raw_args | each { into string })
    {tool: $env.MOCK_TOOL, args: $args} | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
    if ($env.MOCK_UPDATE_WORKFLOW? | default '') == '1' {
        update-command $env.MOCK_TOOL $args
        return
    }
    if (failing $env.MOCK_TOOL) { exit 17 }
    if $env.MOCK_TOOL == 'nix' and (t3-nix $args) { return }
    if $env.MOCK_TOOL == 'git' { git-command $args; return }

    if $env.MOCK_TOOL == 'nix' and $args.0 == 'eval' {
        let prefix = [eval --option eval-cache 'false' --option warn-dirty 'false' --option eval-speculation-threshold '0' --abort-on-warn --show-trace --raw]
        assert equal ($args | drop 1) $prefix
        let target = ($args | last)
        if $target =~ '\.warning\.' { print --stderr 'evaluation warning: fixture' }
        if $target =~ '\.failed\.' { print --stderr 'evaluation failed: fixture'; exit 23 }
        if $target =~ '\.info\.' { print --stderr 'informational trace: fixture' }
        print '/nix/store/fixture-system.drv'
    }
}
