# Replace exactly one known source field; never silently accept layout drift.
def replace-field [source: string, pattern: string, value: string] {
    if ($source | parse --regex $pattern | length) != 1 {
        error make {msg: $"Expected exactly one source field matching: ($pattern)"}
    }
    $source | str replace --regex $pattern {|prefix suffix| $"($prefix)($value)($suffix)"}
}

def desktop-hash [release: record, arch: string] {
    let name = $"opencode-desktop-linux-($arch).AppImage"
    let assets = ($release.assets | where name == $name)
    if ($assets | length) != 1 {
        error make {msg: $"Expected one release asset: ($name)"}
    }
    let digest = ($assets.0.digest? | default '')
    if $digest !~ '^sha256:[0-9a-fA-F]{64}$' {
        error make {msg: $"Release asset ($name) has no valid SHA-256 digest"}
    }
    'sha256-' + ($digest | str replace 'sha256:' '' | decode hex | encode base64)
}

# Validate both files and every release field before writing either definition.
def prepare-update [sources: record, version: string, integrities: record, release: record] {
    if $version !~ '^[0-9A-Za-z.+-]+$' {
        error make {msg: 'Invalid OpenCode version'}
    }
    let desktop_version = ($release.tag_name | str replace --regex '^v' '')
    if $desktop_version != $version {
        error make {msg: $"OpenCode CLI beta is ($version) but desktop beta is ($desktop_version)"}
    }

    mut cli = (replace-field $sources.cli '(version\s*=\s*")[^"]+(";)' $version)
    for platform in [cli-linux-x64-baseline cli-linux-arm64] {
        let integrity = ($integrities | get $platform)
        if $integrity !~ '^sha(256|512)-[A-Za-z0-9+/]+=*$' {
            error make {msg: $"Invalid npm integrity for ($platform)"}
        }
        let pattern = '(packageName = "' + $platform + '";\s+hash = ")[^"]+(";)'
        $cli = (replace-field $cli $pattern $integrity)
    }

    mut desktop = $sources.desktop
    for arch in [x86_64 arm64] {
        let pattern = '(arch = "' + $arch + '";\s+hash = ")[^"]+(";)'
        $desktop = (replace-field $desktop $pattern (desktop-hash $release $arch))
    }
    {cli: $cli, desktop: $desktop}
}

def write-update [directory: path, sources: record] {
    let staged = (mktemp --directory --tmpdir-path $directory .opencode-update.XXXXXX)
    let targets = {cli: opencode.nix, desktop: opencode-desktop.nix}
    try {
        for entry in ($targets | transpose key file) {
            let temporary = ($staged | path join $entry.file)
            $sources | get $entry.key | save $temporary
            ^chmod --reference ($directory | path join $entry.file) $temporary
        }
        for file in ($targets | values) {
            mv --force ($staged | path join $file) ($directory | path join $file)
        }
    } catch {|err|
        rm --recursive --force $staged
        error make {msg: $err.msg}
    }
    rm --recursive --force $staged
}

def main [] {
    let version = (^npm view '@opencode-ai/cli@beta' version | str trim)
    let integrities = ([cli-linux-x64-baseline cli-linux-arm64] | reduce --fold {} {|platform hashes|
        let integrity = (^npm view $"@opencode-ai/($platform)@($version)" dist.integrity | str trim)
        $hashes | insert $platform $integrity
    })
    # npm and GitHub can publish at different times; use the CLI's exact release.
    let release = (^curl --fail --silent --show-error --max-time 60
        $"https://api.github.com/repos/anomalyco/opencode-beta/releases/tags/v($version)" | from json)
    let sources = {
        cli: (open --raw ($env.FILE_PWD | path join opencode.nix))
        desktop: (open --raw ($env.FILE_PWD | path join opencode-desktop.nix))
    }
    let updated = (prepare-update $sources $version $integrities $release)
    write-update $env.FILE_PWD $updated
    print $"Updated opencode2 CLI and desktop to ($version)"
}
