use std/assert
use test-utils.nu [with-scratch assert-success]

# Use packaged executable fixtures: exercise the same exec contract as CI.
def main [guard: path, store: path, upload: path, bound_guard: path] {
    let guard = ($guard | path expand)
    let store = ($store | path expand)
    let upload = ($upload | path expand)
    let bound_guard = ($bound_guard | path expand)
    with-scratch {|scratch|
        $env.NIX_STORE_BIN = $store
        $env.CACHIX_ORIGINAL_HOOK = $upload
        $env.UPLOAD_LOG = ($scratch | path join uploads)
        $env.UPLOAD_STATUS = '0'
        '' | save $env.UPLOAD_LOG

        $env.OUT_PATHS = '/nix/store/test-safe /nix/store/test-marble /nix/store/test-wrapper /nix/store/test-astal-wrapper /nix/store/test-uppercase /nix/store/test-missing /nix/store/test-empty'
        assert-success (^$guard | complete)
        assert equal (open --raw $env.UPLOAD_LOG) "/nix/store/test-safe\n"

        for batch in ['/nix/store/test-wrapper' '' " \t\n "] {
            $env.OUT_PATHS = $batch
            assert-success (^$guard | complete)
        }
        $env.NIX_STORE_BIN = ($scratch | path join does-not-exist)
        $env.OUT_PATHS = '/nix/store/test-safe'
        assert-success (^$guard | complete)
        assert equal (open --raw $env.UPLOAD_LOG) "/nix/store/test-safe\n"

        # Preserve the original hook's failure rather than reporting success.
        $env.NIX_STORE_BIN = $store
        $env.UPLOAD_STATUS = '7'
        assert equal (^$guard | complete).exit_code 7
        $env.NIX_STORE_BIN = ''
        assert ((^$guard | complete).exit_code != 0)
        assert equal (open --raw $env.UPLOAD_LOG | lines | length) 2
        # CI binds the executable paths in a Nix-generated wrapper, independent
        # of the daemon's environment. Exercise that exact packaging entry point.
        $env.CACHIX_ORIGINAL_HOOK = ''
        $env.UPLOAD_STATUS = '0'
        assert-success (^$bound_guard | complete)
        assert equal (open --raw $env.UPLOAD_LOG | lines | length) 3
        print 'PASS: only public closures forwarded; private/transitive/uppercase, failed/empty queries and empty batches blocked; upload failures preserved'
    }
}
