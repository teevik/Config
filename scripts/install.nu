# Install a host with nixos-anywhere, seeding this exact checkout and the
# user's keys. The installed system adopts the seed during activation (see
# modules/nixos/minimal/install-seed.nix), so it boots ready to use.

# Keep in sync with modules/nixos/minimal/install-seed.nix.
const seed = 'var/lib/install-seed'
const keys = [
    {path: .ssh/id_rsa, mode: '0600'}
    {path: .ssh/id_rsa.pub, mode: '0644'}
    {path: .config/sops/age/keys.txt, mode: '0600'}
]

# Mirror the user's home below the seed. Directory modes are explicit because
# nixos-anywhere's tar also applies them to the target's existing directories.
def stage-seed [root: path, stage: path] {
    let home = ($stage | path join $seed)
    ^install -d -m 0755 ($stage | path join var) ($home | path dirname)
    ^install -d -m 0700 $home
    for key in $keys {
        let target = ($home | path join $key.path)
        ^install -d -m 0700 ($target | path dirname)
        ^install -m $key.mode ($env.HOME | path join $key.path) $target
    }
    # Tracked and new nonignored files as they are now, including the generated
    # hardware configuration and uncommitted edits, plus Git metadata. Deleted
    # files and ignored build artifacts stay behind.
    let checkout = ($home | path join Documents/Config)
    ^install -d $checkout
    let files = (^git -C $root ls-files -z --cached --others --exclude-standard
        | split row (char nul)
        | where {|file| $file != '' and ($root | path join $file | path exists --no-symlink) })
    cd $root
    ^cp --archive --parents --target-directory $checkout -- .git ...$files
}

def main [
    target: string # Hostname or IP address, reachable as root over SSH.
    host: string # Host directory in hosts/ with a disk-config.nix.
] {
    let root = ($env.FILE_PWD | path dirname)
    if $target == '' or ($target starts-with '-') or ($target | str contains '@') {
        error make {msg: 'Specify the target hostname or IP, without a username.'}
    }
    if not ($host =~ '^[A-Za-z0-9_-]+$' and ($root | path join hosts $host disk-config.nix | path exists)) {
        error make {msg: 'Specify an installable host from hosts/.'}
    }
    for key in $keys {
        let file = ($env.HOME | path join $key.path)
        if (($file | path type) != file) or ((^test -r $file | complete).exit_code != 0) {
            error make {msg: $"Required installation key is missing or unreadable: ($file)"}
        }
    }
    if (($root | path join .git | path type) != dir) {
        error make {msg: 'Installation requires a normal Git checkout, not a linked worktree.'}
    }
    if ($root | path join .gitmodules | path exists) {
        error make {msg: 'Seeding submodules is not supported.'}
    }

    cd $root
    let common = [--build-on local --no-substitute-on-destination --flake $".#($host)"]
    # Boot the installer and detect hardware first, so the seed includes it.
    ^nixos-anywhere ...$common --phases kexec --generate-hardware-config nixos-generate-config $"hosts/($host)/hardware.nix" $"root@($target)"
    let stage = (mktemp --directory --tmpdir install-seed.XXXXXX)
    try {
        stage-seed $root $stage
        ^nixos-anywhere ...$common --phases disko,install,reboot --extra-files $stage $"root@($target)"
    } catch {|err|
        rm --recursive --force $stage
        error make {msg: $err.msg}
    }
    rm --recursive --force $stage
    print $"Installed ($host); it is rebooting into the new system with this checkout in ~/Documents/Config."
}
