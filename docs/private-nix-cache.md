# Private nightly system cache

The nightly workflow runs on the isolated native homelab runner. One job updates
packages, loads the matching Nix/Cargo plugin, then builds, retains and scans
desktop followed by zenbook. Both builds share `/nix/store` and the job's Git
source/evaluation caches. Nix automatically reuses existing outputs; there is
no separate shared-dependency planner or bootstrap handoff between build jobs.
Only the validated package update crosses to the GitHub-hosted PR job.

`.github/cache/host.sh` performs each host's build, full closure publication and
security scan. Both hosts must succeed before the update PR is created. If one
host fails, the other is still attempted, and completed outputs remain retained.
Encrypted security reports remain separate per host. The runner recycles its
processes and workspace after the complete job, preserving the Nix store.

The native job has no cache signing/SSH keys. Its dedicated Nix daemon roots
successful outputs immediately; `.github/cache/build.py` periodically flushes
these through the restricted local retention socket. Harmonia signs metadata
with its protected key. `.github/cache/publish.py` retains each complete system
closure and verifies its remote receipt, HTTP signatures and archive availability.
Public Cachix caches remain usable upstreams of the homelab proxy.

Caching is per derivation/output, not per compiler invocation. Exact outputs are
reused automatically; changed package sources, toolchains or dependencies can
require new builds. Incomplete compilations cannot be resumed from the cache.
The Cargo plugin gives Zed reuse across unchanged Rust crates, but changed crates
and the final executable can still be expensive. A single job avoids refetching
hundreds of Git sources and reevaluating both host graphs in a separate planner.

The homelab runner, Nix daemon and retention workers share a three-CPU quota,
13 GiB soft / 14 GiB hard memory limit, and low CPU/I/O priority. Details of
isolation, authorization and deployment live in the homelab repository's
`docs/github-runner.md`. Weekly committed-configuration scans still run on
GitHub-hosted runners with read-only access to the cache through Tailscale.

## First use

The native runner and private cache are installed. The hosted weekly workflow
uses a Tailscale identity. For a fresh setup, configure it with:

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

Native nightly jobs use the local retention socket without upload credentials.
The weekly security workflow joins the tailnet for cache reads. The reusable
build retains an optional hosted publication path for clients using
`NIX_CACHE_SSH_KEY` and `NIX_CACHE_SIGNING_KEY`.

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
python3 .github/cache/seed.py --manifest /tmp/cache-seed-paths /run/current-system result-zed-cargo-nix
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
batches and verification state across build steps. An isolated real Nix store
checks that desktop builds a shared dependency and zenbook reuses it without
any planning step. It also verifies that a failed build does not start a scan
and scanners receive no upload credentials. A real isolated Nix build also
exercised the post-build hook. Live validation downloaded a four-path
system into an empty store, verified signatures and contents, and ran GC without
losing its rooted dependencies. Publication after an initial HTTP cache miss
passed with negative-cache TTL disabled during verification.

Desktop seeding completed on 2026-09-23: 17,847 existing outputs (88.6 GiB)
were retained and every path passed private-cache signature verification. This
includes the exact current Nix/plugin bootstrap and Zed crate outputs. Detailed
local evidence is in `.scratch/private-nix-cache/improvements-validation.md`.

On 2026-09-25, the shared dependency stage and the updated Zed crate build were
also built successfully on the desktop. Their outputs were seeded into the
private cache: 2,152 requested outputs, a 9,231-path / 64.1 GiB closure. Two
successive uploads verified each path once using the job verification state.
Evidence is in `.scratch/cache-performance/implementation.md`.
