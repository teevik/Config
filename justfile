install TARGET-IP HOST:
    # Run disko and install nixos
    nix run github:numtide/nixos-anywhere -- \
      --build-on local \
      --no-substitute-on-destination \
      --phases kexec,disko,install \
      --generate-hardware-config nixos-generate-config ./hosts/{{ HOST }}/hardware.nix \
      --flake '.#{{ HOST }}' \
      root@{{ TARGET-IP }}

    # Copy ssh keys over
    ssh teevik@{{ TARGET-IP }} "mkdir -p /mnt/home/teevik/.ssh"
    scp /home/teevik/.ssh/id_rsa teevik@{{ TARGET-IP }}:/mnt/home/teevik/.ssh/id_rsa
    scp /home/teevik/.ssh/id_rsa.pub teevik@{{ TARGET-IP }}:/mnt/home/teevik/.ssh/id_rsa.pub

    # Copy sops age key for secret decryption
    ssh teevik@{{ TARGET-IP }} "mkdir -p /mnt/home/teevik/.config/sops/age"
    scp /home/teevik/.config/sops/age/keys.txt teevik@{{ TARGET-IP }}:/mnt/home/teevik/.config/sops/age/keys.txt

    # Clone config repo
    ssh teevik@{{ TARGET-IP }} "mkdir /mnt/home/teevik/Documents"
    ssh teevik@{{ TARGET-IP }} "git clone https://github.com/teevik/Config.git /mnt/home/teevik/Documents/Config"
    ssh teevik@{{ TARGET-IP }} "cd /mnt/home/teevik/Documents/Config && git remote set-url origin git@github.com:teevik/Config.git"

    # Stow dotfiles
    ssh teevik@{{ TARGET-IP }} "mkdir -p /mnt/home/teevik/.pi/agent && cd /mnt/home/teevik/Documents/Config && stow -t /mnt/home/teevik dotfiles"

    # Reboot
    # ssh root@{{ TARGET-IP }} "reboot"

# Stow dotfiles into home directory
stow:
    mkdir -p ~/.pi/agent
    stow -v -t ~ dotfiles
    npm ci --prefix ~/.omp/agent

# Remove stowed dotfiles
unstow:
    stow -v -t ~ -D dotfiles

# Re-stow dotfiles (useful after adding new files)
restow:
    mkdir -p ~/.pi/agent
    stow -v -t ~ -R dotfiles
    npm ci --prefix ~/.omp/agent

# First-time stow: adopt existing files, then check diff
stow-adopt:
    mkdir -p ~/.pi/agent
    stow -v -t ~ --adopt dotfiles
    @echo "Files adopted. Run 'git diff dotfiles/' to review changes."

# Create required directories
setup:
    mkdir -p ~/.npm-packages/lib
    mkdir -p ~/.pi/agent
    mkdir -p ~/Documents ~/Downloads ~/Music ~/Pictures/Screenshots ~/Videos ~/Desktop ~/Public ~/Templates

# Refresh all flake inputs and package sources, then validate the packages.
[positional-arguments]
update *args:
    @just nu packages/update.nu "$@"

# Quick source-only update; use `just update` to also validate the builds.
update-sources:
    @just nu packages/update.nu --no-build

# Run a repository script with pinned Nu/tools and no personal shell config.
[positional-arguments]
nu +args:
    @nix run --impure --expr 'import ./packages/nu-scripts {}' . -- "$@"

# Pass input names for a targeted update, or omit them to update all inputs.
[positional-arguments]
update-inputs *args:
    @just nu packages/update-inputs.nu "$@"

# Compare parallel updates with native Nix using offline Git fixtures.
update-inputs-check:
    python3 tests/update-inputs.py

# Fetch the locked input graph ahead of offline work; does not update pins.
prefetch-inputs:
    nix eval --impure --json --expr 'import ./tests/evaluation/prefetch-inputs.nix {}'

# Fail on evaluation warnings, with a stack trace for builtins.warn.
[positional-arguments]
eval-warnings *hosts="zenbook":
    @just nu tests/nix-warnings.nu "$@"

# Reveal evaluation-time builds and unusually broad source copies.
eval-diagnostics host="zenbook":
    nix eval --option eval-cache false --option warn-dirty false \
      --option trace-import-from-derivation true \
      --option warn-large-path-threshold 100M \
      --raw '.#nixosConfigurations.{{ host }}.config.system.build.toplevel.drvPath'

# Read-only Nix linting and Nu syntax checking; uses the pinned nixpkgs input.
lint:
    nix run --impure --expr 'import ./packages/nix-lint {}'

# Run the same source lint plus its regression tests in a sandbox (CI entry).
lint-check:
    nix build --file checks/nix-lint.nix --no-link --print-build-logs

# Offline regression tests for Nu helpers, evaluation checks, and update scripts.
script-check:
    nix build --file checks/nu-scripts.nix --no-link --print-build-logs

# Scan the running generation; detailed reports use the existing age recipient.
security-scan output="/tmp/nix-security-report":
    nix run --impure --expr 'import ./packages/security {}' . -- /run/current-system --scope deployed --output {{ quote(output) }}

# Rescan a previously decrypted CycloneDX inventory with current advisories.
security-rescan sbom output="/tmp/nix-security-rescan":
    nix run --impure --expr 'import ./packages/security {}' . -- {{ quote(sbom) }} --sbom --scope inventory --output {{ quote(output) }}

# Verify security report privacy, failure handling, and Actions definitions.
security-check:
    nix build --file checks/security.nix --no-link --print-build-logs

# Inventory existing outputs and build intermediates; add --upload to seed nixbuild.net.
[positional-arguments]
cache-warm +args:
    python3 .github/cache/warm.py "$@"

# Exercise cache inventory and copying against real local Nix outputs.
cache-warm-check:
    python3 tests/cache-warm.py

# Compare uncached NixOS evaluation with Blueprint and a direct nixosSystem prototype.
benchmark-eval host="zenbook" runs="5":
    hyperfine --warmup 1 --runs {{ runs }} --parameter-list engine blueprint,native \
      'nix eval --option eval-cache false --impure --raw --file tests/evaluation/benchmark.nix --argstr engine {engine} --argstr host {{ host }} drvPath'

# Compare evaluator threads against the same source snapshot used by nh.
benchmark-eval-cores host=`hostname` runs="5":
    #!/usr/bin/env bash
    set -euo pipefail
    flake_source="$(nix eval --impure --raw --file tests/evaluation/source-snapshot.nix)"
    hyperfine --warmup 1 --runs {{ runs }} --parameter-list cores 1,2,4,8,16 \
      "nix eval --option eval-cache false --option eval-cores {cores} --raw 'path:$flake_source#nixosConfigurations.{{ host }}.config.system.build.toplevel.drvPath'"

# Snapshot tracked Nix sources, preserving cache hits across unrelated dotfile edits.
# nh prepares this automatically; this recipe is useful for manual cache lookups.
flake-source:
    @nix eval --impure --raw --file tests/evaluation/source-snapshot.nix

# Compare a derivation lookup with and without Nix's evaluation cache; no builds.
benchmark-eval-cache host="zenbook" runs="5":
    hyperfine --warmup 1 --runs {{ runs }} --parameter-list cache false,true \
      'nix path-info --derivation --option eval-cache {cache} .#nixosConfigurations.{{ host }}.config.system.build.toplevel'

# Build and activate local Marble and Astal working trees without publishing them
marble-dev-switch:
    nh os switch -- \
      --override-input marble "path:${HOME}/Documents/Projects/marble-shell" \
      --override-input astal "path:${HOME}/Documents/Projects/astal"

build-iso:
    nix run "nixpkgs#nixos-generators" -- --format iso --flake ".#minimal"
