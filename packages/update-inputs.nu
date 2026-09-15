# Keep Nix responsible for graph construction, follows, hashing and validation.
# Only resolve the independent remote roots concurrently.
def main [
    --flake: path # Checkout to update; defaults to this repository.
    --serial # Use the ordinary Nix updater, without parallel prefetching.
    ...inputs: string # Optional input names for a native targeted update.
] {
    let root = ($flake | default ($env.FILE_PWD | path dirname) | path expand)
    cd $root
    if $serial or ($inputs | is-not-empty) {
        ^nix flake update ...$inputs
        return
    }

    let source = (open --raw flake.nix)
    let previous = if ('flake.lock' | path exists) { open --raw flake.lock } else { null }
    let resolved = (^nix eval --impure --json --option tarball-ttl 0 --option eval-cores 16
        --file ($env.FILE_PWD | path join nu-scripts/resolve-inputs.nix) --argstr root $root result | from json)
    if ($resolved | is-empty) {
        ^nix flake update
        return
    }

    # Stage on the same filesystem so the final rename is atomic.
    let staging = (mktemp --directory --tmpdir-path $root .flake-update.XXXXXX)
    try {
        let lock_path = ($staging | path join flake.lock)
        let overrides = ($resolved | each {|input| [--override-input $input.name $input.resolved] } | flatten)
        ^nix flake update ...$overrides --output-lock-file $lock_path
        mut lock = (open --raw $lock_path | from json)
        mut root_node = ($lock.nodes | get $lock.root)
        for input in $resolved {
            # Nix can share a node between a mutable root and a pinned nested
            # input. Clone it before restoring the root's original declaration.
            let old = ($root_node.inputs | get $input.name)
            mut name = $"_refresh_($input.name)"
            while ($name in ($lock.nodes | columns)) { $name = $name + '_' }
            let node = ($lock.nodes | get $old | upsert original $input.original)
            $lock = ($lock | update nodes ($lock.nodes | insert $name $node))
            $root_node = ($root_node | update inputs ($root_node.inputs | update $input.name $name))
        }
        let root_name = $lock.root
        $lock = ($lock | update nodes ($lock.nodes | update $root_name $root_node))
        $lock | to json --indent 2 | save --force $lock_path

        # Validate against the real declarations and let Nix canonicalize node
        # names/deduplication. Unlocked transitive inputs were refreshed by the
        # native update above (which always sets tarball-ttl to zero).
        let metadata = (^nix flake metadata --reference-lock-file $lock_path
            --no-update-lock-file --no-write-lock-file --json | from json)
        let updated = ($metadata.locks | to json --indent 2) + "\n"
        let current = if ('flake.lock' | path exists) { open --raw flake.lock } else { null }
        if (open --raw flake.nix) != $source or $current != $previous {
            error make {msg: 'flake.nix or flake.lock changed during the update; retry with the current files'}
        }
        if $updated != $previous {
            $updated | save --force $lock_path
            if $previous == null { ^chmod 644 $lock_path } else { ^chmod --reference flake.lock $lock_path }
            mv --force $lock_path flake.lock
            print 'Updated flake.lock'
        } else {
            print 'Flake inputs are already current'
        }
    } catch {|err|
        rm --recursive --force $staging
        error make {msg: $err.msg}
    }
    rm --recursive --force $staging
}
