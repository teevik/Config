# Refresh the T3 Code nightly. Fixed-output dependencies keep their hash, and
# therefore their store path, unless the source files that determine them
# changed; the others are refetched together in one Nix build.

const repository = 'https://github.com/pingdotgg/t3code'
const tag_pattern = '^\S+\s+refs/tags/v(?<version>[0-9]+\.[0-9]+\.[0-9]+-nightly\.(?<date>[0-9]{8})\.(?<build>[0-9]+))$'

# Source paths that determine each dependency's contents, besides its recipe.
const dependency_inputs = {
    pnpmDeps: [package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc]
    licenseNotices: [
        third-party-licenses.config.json
        scripts/sync-third-party-license-notices.ts
        scripts/lib
        .generated/third-party-licenses
    ]
}

# Tags are cheap to list and, unlike the releases API, not rate limited.
def latest-version [] {
    let tags = (^git ls-remote --tags --refs $repository 'v*-nightly.*' | lines
        | parse --regex $tag_pattern
        | into int build)
    if ($tags | is-empty) { error make {msg: 'No T3 Code nightly tags found'} }
    ($tags | sort-by date build | last).version
}

def current-state [targets: path] {
    (^nix eval --json --file $targets t3code-nightly --apply 'p: {
        inherit (p) version;
        srcPath = p.src.outPath;
        hashes = {
            src = p.src.outputHash;
            pnpmDeps = p.pnpmDeps.outputHash;
            licenseNotices = p.licenseNotices.outputHash;
        };
    }' | from json)
}

# A valid hash that no real output has, unique per input so mismatches map back.
def placeholder [attr: string] {
    'sha256-' + ($"t3code-nightly update placeholder: ($attr)" | hash sha256 --binary | encode base64)
}

def replace-once [file: path, old: string, new: string] {
    let source = (open --raw $file)
    if (($source | split row $old | length) - 1) != 1 {
        error make {msg: $"Expected exactly one occurrence of ($old) in ($file)"}
    }
    $source | str replace $old $new | save --force $file
}

def set-version [file: path, version: string] {
    let pattern = '(version = ")[^"]+(";)'
    let source = (open --raw $file)
    if ($source | parse --regex $pattern | length) != 1 {
        error make {msg: $"Expected exactly one version field in ($file)"}
    }
    $source | str replace --regex $pattern {|prefix suffix| $"($prefix)($version)($suffix)"} | save --force $file
}

# Missing paths fingerprint as null; directories by every file they contain.
def fingerprint [root: path, paths: list<string>] {
    $paths | each {|relative|
        let path = ($root | path join $relative)
        if not ($path | path exists) {
            null
        } else if ($path | path type) == dir {
            glob $"($path)/**/*" --no-dir | sort | each {|file|
                [($file | path relative-to $path) (open --raw $file | hash sha256)]
            }
        } else {
            open --raw $path | hash sha256
        }
    }
}

# Build the inputs together, adopting the hash Nix reports for each placeholder
# or stale hash. Nix registers a mismatched output under its real hash, so the
# confirming build reuses it rather than fetching again.
def build-inputs [targets: path, file: path, attrs: list<string>] {
    let installables = ($attrs | each {|attr| $"t3code-nightly.($attr)" })
    let names = ($attrs | each {|attr| $'"($attr)"' } | str join ' ')
    for _ in 1..3 {
        let log = (mktemp --tmpdir t3code-update.XXXXXX)
        # Stream the build output while keeping a copy to parse. The exit status
        # does not survive the pipe, so success is checked by output paths below.
        ^nix build --no-link --keep-going --file $targets ...$installables e>| tee { save --force $log } | print
        let mismatches = (open --raw $log
            | parse --regex 'specified:\s+(?<specified>sha256-\S+)\s+got:\s+(?<got>sha256-\S+)')
        rm $log
        if ($mismatches | is-empty) {
            let outputs = (^nix eval --json --file $targets t3code-nightly
                --apply ('p: map (a: p.${a}.outPath) [ ' + $names + ' ]') | from json)
            if ($outputs | all {|path| $path | path exists }) { return }
            error make {msg: 'T3 Code dependency build failed; see the Nix output above'}
        }
        for mismatch in $mismatches {
            replace-once $file $mismatch.specified $mismatch.got
        }
    }
    error make {msg: 'T3 Code dependency hashes did not settle after three builds'}
}

def update [targets: path, file: path, current: record, version: string] {
    set-version $file $version
    replace-once $file $current.hashes.src (placeholder src)
    build-inputs $targets $file [src]

    let source = (^nix eval --raw --file $targets t3code-nightly.src.outPath)
    let attrs = ($dependency_inputs | columns)
    let stale = if ($current.srcPath | path exists) {
        $attrs | where {|attr|
            let paths = ($dependency_inputs | get $attr)
            (fingerprint $current.srcPath $paths) != (fingerprint $source $paths)
        }
    } else {
        # Without the previous source there is nothing to compare against.
        $attrs
    }
    for attr in $stale {
        replace-once $file ($current.hashes | get $attr) (placeholder $attr)
    }
    let reused = ($attrs | where {|attr| $attr not-in $stale })
    if ($reused | is-not-empty) { print $"Inputs unchanged, reusing: ($reused | str join ', ')" }
    if ($stale | is-not-empty) { print $"Refreshing: ($stale | str join ', ')" }
    # Reused hashes are built too: a no-op when present, verified when not.
    build-inputs $targets $file $attrs
}

def main [--no-build] {
    let targets = ($env.FILE_PWD | path join update-targets.nix)
    let file = ($env.FILE_PWD | path join t3code-nightly.nix)
    let version = (latest-version)
    let current = (current-state $targets)
    if $version == $current.version {
        print $"T3 Code nightly is already ($version)"
    } else {
        print $"Updating T3 Code nightly ($current.version) -> ($version)"
        # Leave the definition consistent: either fully updated or untouched.
        let original = (open --raw $file)
        try {
            update $targets $file $current $version
        } catch {|err|
            $original | save --force $file
            error make {msg: $err.msg}
        }
    }

    if not $no_build {
        ^nix build --no-link --print-build-logs --file $targets t3code-nightly
    }
}
