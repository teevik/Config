# Installation bootstrap: the local seed staging (scripts/install.nu) against
# an offline nixos-anywhere double, and the target's adoption of that seed
# (modules/nixos/minimal/install-seed.sh) in a scratch home with a logging
# chown. Never contacts a machine or changes real ownership.
use std/assert
use test-utils.nu [with-scratch assert-success]

const keys = {
    .ssh/id_rsa: "fixture private key\n"
    .ssh/id_rsa.pub: "fixture public key\n"
    .config/sops/age/keys.txt: "fixture age key\n"
}

def calls [] { open --raw $env.MOCK_LOG | lines | each { from json } }

def fixture-repo [scratch: path, source: path] {
    let repo = ($scratch | path join repo)
    mkdir ($repo | path join scripts) ($repo | path join hosts/zenbook) ($repo | path join hosts/minimal)
    cp ($source | path join scripts/install.nu) ($repo | path join scripts)
    '{}' | save ($repo | path join hosts/zenbook/disk-config.nix)
    "old hardware\n" | save ($repo | path join hosts/zenbook/hardware.nix)
    '{}' | save ($repo | path join hosts/minimal/configuration.nix)
    "delete me\n" | save ($repo | path join deleted.txt)
    "ignored/\n" | save ($repo | path join .gitignore)
    ^git -C $repo init --quiet
    ^git -C $repo add .
    ^git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m fixture
    $repo
}

def install-tests [source: path] {
    with-scratch {|scratch|
        let repo = (fixture-repo $scratch $source)
        $env.HOME = ($scratch | path join local-home)
        for key in ($keys | transpose path text) {
            mkdir ($env.HOME | path join $key.path | path dirname)
            $key.text | save ($env.HOME | path join $key.path)
        }
        $env.MOCK_LOG = ($scratch | path join calls.jsonl)
        let install = {|...args|
            '' | save --force $env.MOCK_LOG
            ^$nu.current-exe --no-config-file ($repo | path join scripts/install.nu) ...$args | complete
        }

        # Working-tree state the seed must preserve exactly.
        rm ($repo | path join deleted.txt)
        "new module\n" | save ($repo | path join new.nix)
        mkdir ($repo | path join ignored)
        "build result\n" | save ($repo | path join ignored/artifact)
        $env.MOCK_FAILURE = ''
        let result = (do $install example.invalid zenbook)
        assert-success $result
        let calls = (calls)
        assert equal ($calls | length) 2
        let flake = [--build-on local --no-substitute-on-destination --flake .#zenbook]
        assert equal $calls.0.args ($flake | append [--phases kexec --generate-hardware-config nixos-generate-config hosts/zenbook/hardware.nix root@example.invalid])
        assert equal $calls.1.args ($flake | append [--phases 'disko,install,reboot' --extra-files $calls.1.stage root@example.invalid])
        let upload = $calls.1.upload
        # Parents of the keys follow the local umask; everything else is explicit.
        let staged = ($upload.entries | where path !~ '/Documents')
        let explicit = [
            [path mode];
            [. '700']
            [var '755']
            [var/lib '755']
            [var/lib/install-seed '700']
            [var/lib/install-seed/.ssh '700']
            [var/lib/install-seed/.ssh/id_rsa '600']
            [var/lib/install-seed/.ssh/id_rsa.pub '644']
            [var/lib/install-seed/.config/sops/age '700']
            [var/lib/install-seed/.config/sops/age/keys.txt '600']
        ]
        assert equal ($staged | where path not-in [var/lib/install-seed/.config var/lib/install-seed/.config/sops] | sort-by path) ($explicit | sort-by path)
        assert $upload.keys_match
        for text in ($keys | values) {
            assert not (($result.stdout + $result.stderr) | str contains $text) 'Key contents were printed'
        }
        print 'PASS: keys staged privately with explicit target directory modes'

        # Hardware detection runs before staging, so the seed carries its result.
        assert equal $upload.hardware "generated hardware\n"
        assert $upload.git_head
        let checkout = ($upload.entries | where path =~ '/Documents/Config/' | get path | each { str replace --regex '.*/Documents/Config/' '' })
        assert ('new.nix' in $checkout)
        assert ('scripts/install.nu' in $checkout)
        assert ('deleted.txt' not-in $checkout)
        assert (($checkout | where $it =~ '^ignored') | is-empty)
        assert not ($calls.1.stage | path exists) 'Seed stage was left behind'
        print 'PASS: seed is the exact working tree after hardware detection, then removed'

        $env.MOCK_FAILURE = 'install'
        let result = (do $install example.invalid zenbook)
        assert ($result.exit_code != 0)
        assert equal (calls | length) 2
        assert not ((calls).1.stage | path exists) 'Seed stage survived a failed installation'
        $env.MOCK_FAILURE = 'kexec'
        let result = (do $install example.invalid zenbook)
        assert ($result.exit_code != 0)
        assert equal (calls | length) 1
        $env.MOCK_FAILURE = ''
        print 'PASS: installer failures stop the run and remove the stage'

        for args in [[teevik@example.invalid zenbook] [-oProxyCommand=x zenbook] [example.invalid minimal] [example.invalid ../zenbook]] {
            let result = (do $install ...$args)
            assert ($result.exit_code != 0) $"Accepted ($args)"
            assert equal (calls) []
        }
        mv ($env.HOME | path join .config/sops/age/keys.txt) ($scratch | path join keys.txt)
        let result = (do $install example.invalid zenbook)
        assert ($result.stderr =~ 'missing or unreadable')
        assert equal (calls) []
        mv ($scratch | path join keys.txt) ($env.HOME | path join .config/sops/age/keys.txt)
        mv ($repo | path join .git) ($scratch | path join git)
        "gitdir: /unavailable\n" | save ($repo | path join .git)
        let result = (do $install example.invalid zenbook)
        assert ($result.stderr =~ 'normal Git checkout')
        assert equal (calls) []
        print 'PASS: invalid targets, hosts, keys and checkouts fail before contacting the target'
    }
}

def adoption-tests [source: path] {
    let adopt = ($source | path join modules/nixos/minimal/install-seed.sh)
    assert ((open --raw ($source | path join modules/nixos/minimal/install-seed.nix)) | str contains '/var/lib/install-seed')
    assert ((open --raw ($source | path join scripts/install.nu)) | str contains "const seed = 'var/lib/install-seed'")
    with-scratch {|scratch|
        # Record ownership changes instead of making them, so tests need no root.
        let bin = ($scratch | path join bin)
        mkdir $bin
        $"#!($nu.current-exe) --no-config-file\n" + (open --raw ($source | path join tests/nu-fixtures/chown.nu)) | save ($bin | path join chown)
        ^chmod +x ($bin | path join chown)
        $env.PATH = ($env.PATH | prepend $bin)
        $env.MOCK_LOG = ($scratch | path join calls.jsonl)
        $env.MOCK_FAILURE = ''
        let seed = ($scratch | path join seed)
        let home = ($scratch | path join home)
        let make_seed = {||
            rm --recursive --force $seed
            mkdir ($seed | path join .ssh) ($seed | path join .config/sops/age) ($seed | path join Documents/Config/.git)
            "private\n" | save ($seed | path join .ssh/id_rsa)
            ^chmod 0600 ($seed | path join .ssh/id_rsa)
            ^chmod 0700 ($seed | path join .ssh) $seed
            "age\n" | save ($seed | path join .config/sops/age/keys.txt)
            "ref: refs/heads/main\n" | save ($seed | path join Documents/Config/.git/HEAD)
            "seeded\n" | save ($seed | path join Documents/Config/flake.nix)
        }
        let run = {||
            '' | save --force $env.MOCK_LOG
            ^bash $adopt $seed $home teevik users | complete
        }
        let chowned = {|| calls | each {|call| assert equal ($call.args | first 3) [-R -- teevik:users]; $call.args.3 | path relative-to $seed } | sort }

        # A fresh home receives every entry whole, owned by the user.
        mkdir $home
        do $make_seed
        assert-success (do $run)
        assert equal (do $chowned) ([.config .ssh Documents] | sort)
        assert equal (open --raw ($home | path join .ssh/id_rsa)) "private\n"
        assert equal (^stat --format '%a' ($home | path join .ssh/id_rsa) | str trim) '600'
        assert equal (^stat --format '%a' ($home | path join .ssh) | str trim) '700'
        assert equal (open --raw ($home | path join .config/sops/age/keys.txt)) "age\n"
        assert equal (open --raw ($home | path join Documents/Config/flake.nix)) "seeded\n"
        assert not ($seed | path exists) 'Seed with private keys lingered'
        print 'PASS: adoption moves the seed into a fresh home and removes it'

        # Later activations without a seed change nothing.
        assert-success (do $run)
        assert equal (calls) []
        print 'PASS: activation without a seed is a no-op'

        # Existing directories are merged into; files, checkouts and symlinks are never replaced.
        rm --recursive --force $home
        mkdir ($home | path join .config/app) ($home | path join Documents/Config) ($scratch | path join elsewhere)
        "user checkout\n" | save ($home | path join Documents/Config/flake.nix)
        ^ln -s ($scratch | path join elsewhere) ($home | path join .ssh)
        do $make_seed
        let result = (do $run)
        assert-success $result
        assert equal (do $chowned) [.config/sops]
        assert equal (open --raw ($home | path join .config/sops/age/keys.txt)) "age\n"
        assert ($home | path join .config/app | path exists)
        assert equal (open --raw ($home | path join Documents/Config/flake.nix)) "user checkout\n"
        assert not ($home | path join Documents/Config/.git | path exists) 'Seed merged into an existing checkout'
        assert equal (ls ($scratch | path join elsewhere) | length) 0
        assert ($result.stderr =~ 'keeping existing .*/Documents/Config')
        assert ($result.stderr =~ 'keeping existing .*/\.ssh')
        assert not ($seed | path exists)
        print 'PASS: adoption never replaces or merges into existing checkouts, files or symlinks'

        # Failures keep the seed for the next activation.
        rm --recursive --force $home
        do $make_seed
        assert ((do $run).exit_code != 0)
        assert ($seed | path join .ssh/id_rsa | path exists)
        mkdir $home
        $env.MOCK_FAILURE = 'chown'
        assert ((do $run).exit_code != 0)
        assert ($seed | path join .config/sops/age/keys.txt | path exists)
        assert equal (ls --all $home | length) 0
        $env.MOCK_FAILURE = ''
        assert-success (do $run)
        assert equal (open --raw ($home | path join .ssh/id_rsa)) "private\n"
        assert not ($seed | path exists)
        print 'PASS: failed adoption keeps the seed and a rerun completes it'
    }
}

def main [source: path] {
    let source = ($source | path expand)
    install-tests $source
    adoption-tests $source
}
