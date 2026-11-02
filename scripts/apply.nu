# Build this host's configuration, then switch to it, or stage it for the next
# boot when the kernel, initrd or kernel modules differ from the booted ones.
# Switching then would pair new userspace drivers (NVIDIA) with old modules.
def main [] {
    let out = (mktemp --directory --tmpdir config-apply.XXXXXX)
    try {
        let system = ($out | path join system)
        ^nh os build --out-link $system
        let changed = ([kernel initrd kernel-modules] | where {|part|
            ($system | path join $part | path expand) != ('/run/booted-system' | path join $part | path expand)
        })
        if ($changed | is-empty) {
            ^nh os switch $system
        } else {
            ^nh os boot $system
            print $"(ansi yellow_bold)Reboot to finish the update:(ansi reset) ($changed | str join ', ') changed"
        }
    } catch {|err|
        rm --recursive --force $out
        error make {msg: $err.msg}
    }
    rm --recursive --force $out
}
