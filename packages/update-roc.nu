# Update both Linux architectures from one nightly release before writing.
def main [] {
    let token = ($env.GITHUB_TOKEN? | default '')
    let headers = if $token == '' { [] } else { [--header '@-'] }
    let authorization = if $token == '' { '' } else { $"Authorization: Bearer ($token)\n" }
    let response = ($authorization | ^curl --fail --silent --show-error --max-time 60 ...$headers
        'https://api.github.com/repos/roc-lang/nightlies/releases/latest' | complete)
    if $response.exit_code != 0 {
        error make {msg: $"Failed to fetch Roc nightly: ($response.stderr)"}
    }
    let release = ($response.stdout | from json)
    if $release.tag_name !~ '^nightly-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-f]{7,40}$' {
        error make {msg: 'Invalid Roc nightly tag'}
    }
    let version = ($release.tag_name | str replace 'nightly-' '')
    let file = ($env.FILE_PWD | path join roc-nightly.nix)
    mut source = (open --raw $file)
    let fields = [
        {pattern: '(version\s*=\s*")[^"]+(";)', value: $version}
    ]
    mut replacements = $fields
    for arch in [x86_64 arm64] {
        let name = $"roc_nightly-linux_($arch)-($version).tar.gz"
        let assets = ($release.assets | where name == $name)
        if ($assets | length) != 1 {
            error make {msg: $"Expected one Roc release asset: ($name)"}
        }
        let digest = ($assets.0.digest? | default '')
        if $digest !~ '^sha256:[0-9a-fA-F]{64}$' {
            error make {msg: $"Roc release asset ($name) has no valid SHA-256 digest"}
        }
        $replacements = ($replacements | append {
            pattern: ('(arch = "' + $arch + '";\s+hash = ")[^"]+(";)')
            value: ('sha256-' + ($digest | str replace 'sha256:' '' | decode hex | encode base64))
        })
    }
    for field in $replacements {
        if ($source | parse --regex $field.pattern | length) != 1 {
            error make {msg: $"Expected exactly one Roc source field matching: ($field.pattern)"}
        }
        $source = ($source | str replace --regex $field.pattern {|prefix suffix| $"($prefix)($field.value)($suffix)"})
    }
    $source | save --force $file
    print $"Updated Roc nightly to ($version)"
}
