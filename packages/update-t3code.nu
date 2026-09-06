def main [--no-build] {
    let targets = ($env.FILE_PWD | path join update-targets.nix)
    (^nix-update --file $targets
        --version unstable
        --version-regex '^v([0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+)$'
        --use-github-releases
        --subpackage resourceMonitor
        t3code-nightly)

    if not $no_build {
        ^nix build --no-link --print-build-logs --file $targets t3code-nightly
    }
}
