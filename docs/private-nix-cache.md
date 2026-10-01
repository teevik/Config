# Private nightly system cache

The nightly workflow uses one GitHub-hosted `ubuntu-24.04` VM. It updates
packages, then builds, retains and scans desktop followed by zenbook.
Both builds share the VM's `/nix/store` and Git
source/evaluation caches. Nix automatically reuses existing outputs; there is
no separate shared-dependency planner or handoff between build jobs.
Only the validated package update crosses to the separate PR job.

`.github/cache/host.sh` performs each host's build, full closure publication and
security scan. Both hosts must succeed before the update PR is created. If one
host fails, the other is still attempted. Encrypted security reports remain
separate per host. The GitHub App token is only available to the PR job.

The hosted VM reads the homelab cache through Tailscale OIDC. Successful new
build outputs are queued by a fast post-build hook; `.github/cache/build.py`
signs, uploads, retains and verifies batches every 60 seconds and when each
command finishes, including ordinary build failures. Build-only dependencies
such as Rust crates survive in the private cache for reuse by later runs.
Verified paths are remembered within the job so overlapping batches do not
repeat signature checks. Complete host publication still verifies every path,
the remote retention receipt, signatures and archive availability.

After a batch is remotely retained and verified, its upload-only local GC roots
are removed. Nix's active builds, security-tool link and host
output links retain the paths still needed locally. Failed uploads stay rooted
for the rest of the VM job. Nix reclaims unused paths below 8 GiB free disk,
aiming for 20 GiB free; it does not discard the first host's rooted runtime
closure before building the second host. Initial image cleanup also frees disk.
One derivation builds at a time with up to four build cores and two evaluation
cores, limiting memory contention on the standard 16 GB runner.

Caching is per derivation/output, not per compiler invocation. Exact outputs are
reused automatically; changed package sources, toolchains or dependencies can
require new builds. Incomplete compilations cannot be resumed from the cache.
Zed uses `pkgs.zed-editor` from the locked nixpkgs revision, so its releases can
use the public binary cache without our own Git HEAD build or Cargo plugin.
GitHub creates a fresh VM for
each run, so cached store paths must be downloaded again. Neither private store
contents nor fetcher caches are saved in publicly accessible Actions caches.

Homelab now only serves and retains the cache; it no longer runs GitHub jobs.
Its availability is still required for private downloads and successful
publication. The native runner's service, private daemon and local retention
socket have been removed, along with Config's unused native client path.
Weekly committed-configuration scans also use one GitHub-hosted VM to scan
desktop then zenbook with shared store contents and read-only cache access.
All workflow jobs use the tested Ubuntu 24.04 runner image explicitly.

Clients prefer the homelab proxy and also configure `https://cache.nixos.org`
as a fallback for public packages, with a 15-second connection timeout. A
two-second timeout could disable the only substituter during a package update,
triggering source builds of otherwise cached toolchains and their dependencies.
`fallback = true` permits source builds; it does not supply a backup cache.
Before activating the updated machine configuration, the equivalent temporary
settings in `~/.config/nix/nix.conf` are:

```conf
connect-timeout = 15
extra-substituters = https://cache.nixos.org
```

Remove those temporary settings after activating the machine configuration.

## First use

The private cache and hosted workflow credentials are installed. For a fresh
setup, configure the Tailscale identity with:

```sh
bash .scratch/private-nix-cache/tailscale-setup.sh
```

The wizard creates a restricted CI tag/grant, policy tests and a GitHub OIDC
identity. Existing allow-all rules must be narrowed to exclude the CI tag;
adding a restrictive grant alone does not remove existing access.

Commit the workflow/client changes and put them on main before running the
nightly workflow. The identity is deliberately bound to main and the reusable
`nix-build.yml` workflow. GitHub requires these repository variables:

- `NIX_CACHE_TS_CLIENT_ID`
- `NIX_CACHE_TS_AUDIENCE`
- `NIX_CACHE_POLICY_READY=true`

The nightly caller explicitly passes `NIX_CACHE_SSH_KEY` and
`NIX_CACHE_SIGNING_KEY` to the reusable workflow. They are scoped to publication
steps, removed from build/scanner environments, and written to temporary
mode-0600 files only while uploading. The weekly security workflow does not
receive upload credentials. Both workflows run only on main for scheduled or
manual events; only the separate PR job receives the GitHub App write token.

Until a machine activates the new trusted cache key, use this once from the
Config directory (after a successful nightly run):

```sh
nh os switch --option extra-trusted-public-keys "$(cat modules/nixos/minimal/homelab-cache.pub)"
```

Subsequent rebuilds use the key in the NixOS configuration. Stay connected to
Tailscale. Pull the exact update and keep private submodules/inputs aligned;
local configuration changes can produce different outputs that CI never
built. Desktop seeding can populate existing outputs before the first successful
nightly run.

## Installing a new PC over LAN

Run `just install TARGET-IP HOST` from a machine connected to Tailscale with
the homelab cache and its signing key configured. The recipe uses
`--build-on local` to download cached paths or build missing outputs on that
machine, then transfers the complete closures to the installer over LAN SSH.
`--no-substitute-on-destination` prevents the installer from trying to fetch
dependencies itself. The installer does not need Tailscale for this transfer.

The local machine must support building for the target architecture. Newly
generated hardware configuration and installation tools can still require
builds; nightly CI retains complete runtime systems only for desktop and
zenbook. Connect the installed PC to Tailscale before rebuilding directly on it.

## Retention and checks

The homelab retains 14 successful full generations per host using Nix GC
roots. Its 500 GiB system-closure budget is a warning threshold. Build dependencies
have separate roots grouped by bootstrap, updater, host or desktop seed; batches
expire after 14 days and older batches are evicted above 250 GiB of unique closure
contents. A single batch over that budget is rejected. System roots are never
removed by dependency eviction. Expiration runs both at publication and before
the daily GC. A 300 GiB free-space reserve rejects new uploads. ncps retains its
separate 200 GB disposable proxy cache. Shared paths occupy store space only once.
The deployment and operational details are documented in the homelab repository's
`docs/private-nix-cache.md`.

## Seeding from an existing machine

`.github/cache/seed.py` enumerates existing outputs reachable from local package
or system derivations. It never realises missing paths or starts builds. Review
the manifest before uploading:

```sh
python3 .github/cache/seed.py --manifest /tmp/cache-seed-paths /run/current-system
```

Repeat with `--upload` to sign, copy and retain the selection. Supply credentials
through `NIX_CACHE_SSH_KEY_FILE` and `NIX_CACHE_SIGNING_KEY_FILE`, pointing to
mode-0600 files outside the repository/store, or the corresponding variables
without `_FILE`. The encrypted backups are in the homelab repository's SOPS
secrets. Do not print their values. The publisher uses the same restricted SSH
account and pinned host key as CI. It verifies the retained closure digest and
cache signatures before reporting success.

```sh
nix build --file checks/security.nix --no-link --print-build-logs
nix build --file checks/nix-lint.nix --no-link --print-build-logs
```

Publication tests cover missing/signed metadata, unavailable archives, full
closure membership, mismatched remote receipts, upload retries, and preserving
completed outputs and exit status after a failed build. They also cover overlapping
batches and verification state across build steps, releasing local GC roots
only after verified remote retention, and protecting outputs after failed uploads. An isolated real Nix store
checks that desktop builds a shared dependency and zenbook reuses it without
any planning step. It also verifies that a failed build does not start a scan
and scanners receive no upload credentials. A real isolated Nix build also
exercised the post-build hook. Live validation downloaded a four-path
system into an empty store, verified signatures and contents, and ran GC without
losing its rooted dependencies. Publication after an initial HTTP cache miss
passed with negative-cache TTL disabled during verification.

Desktop seeding completed on 2026-09-23: 17,847 existing outputs (88.6 GiB)
were retained and every path passed private-cache signature verification. This
included the then-current Nix/plugin bootstrap and custom Zed crate outputs. Detailed
local evidence is in `.scratch/private-nix-cache/improvements-validation.md`.

On 2026-09-25, the shared dependency stage and the updated Zed crate build were
also built successfully on the desktop. Their outputs were seeded into the
private cache: 2,152 requested outputs, a 9,231-path / 64.1 GiB closure. Two
successive uploads verified each path once using the job verification state.
Evidence is in `.scratch/cache-performance/implementation.md`.
