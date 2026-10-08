# Offline nixos-anywhere double: records each call and what it would upload,
# never contacting a machine. Key contents are compared, never logged.
def snapshot [stage: path] {
    let checkout = ($stage | path join var/lib/install-seed/Documents/Config)
    let entries = (glob $"($stage)/**/*" --no-symlink
        | where {|entry| not ($entry | path relative-to $stage | str starts-with 'var/lib/install-seed/Documents/Config/.git/') }
        | each {|entry| {
            path: ($entry | path relative-to $stage | if $in == '' { '.' } else { $in })
            mode: (^stat --format '%a' $entry | str trim)
        } }
        | sort-by path)
    let keys = [.ssh/id_rsa .ssh/id_rsa.pub .config/sops/age/keys.txt]
    {
        entries: $entries
        keys_match: ($keys | all {|key|
            (open --raw ($stage | path join var/lib/install-seed $key)) == (open --raw ($env.HOME | path join $key))
        })
        hardware: (open --raw ($checkout | path join hosts/zenbook/hardware.nix))
        git_head: ($checkout | path join .git/HEAD | path exists)
    }
}

# The argument `offset` places after the first occurrence of `name`, if any.
def option [args: list<string>, name: string, offset: int = 1] {
    let found = ($args | enumerate | where item == $name)
    if ($found | is-empty) { null } else { $args | get ($found.0.index + $offset) }
}

def --wrapped main [...raw_args] {
    let args = ($raw_args | each { into string })
    let stage = (option $args '--extra-files')
    {
        args: $args
        stage: $stage
        upload: (if $stage == null { null } else { snapshot $stage })
    } | to json --raw | $in + "\n" | save --append $env.MOCK_LOG
    if ($env.MOCK_FAILURE? | default '') in (option $args '--phases' | split row ,) { exit 17 }
    let hardware = (option $args '--generate-hardware-config' 2)
    if $hardware != null { "generated hardware\n" | save --force $hardware }
}
