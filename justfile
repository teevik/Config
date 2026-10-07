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
    ssh teevik@{{ TARGET-IP }} "cd /mnt/home/teevik/Documents/Config && stow -t /mnt/home/teevik dotfiles"

# Stow dotfiles into home directory
stow:
    stow -v -t ~ dotfiles

# Remove stowed dotfiles
unstow:
    stow -v -t ~ -D dotfiles

# Re-stow dotfiles (useful after adding new files)
restow:
    stow -v -t ~ -R dotfiles

# First-time stow: adopt existing files, then check diff
stow-adopt:
    stow -v -t ~ --adopt dotfiles
    @echo "Files adopted. Run 'git diff dotfiles/' to review changes."

# Create required directories
setup:
    mkdir -p ~/.npm-packages/lib
    mkdir -p ~/Documents ~/Downloads ~/Music ~/Pictures/Screenshots ~/Videos ~/Desktop ~/Public ~/Templates

# Refresh all flake inputs and package sources, then validate the packages.
# Pass --no-build to refresh sources without validation builds.
[positional-arguments]
update *args:
    @just nu packages/update.nu "$@"

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
    nix flake prefetch-inputs

# Read-only Nix linting and Nu syntax checking; uses the pinned nixpkgs input.
lint:
    nix run --impure --expr 'import ./packages/nix-lint {}'

# Run the same source lint plus its regression tests in a sandbox (CI entry).
lint-check:
    nix build --file checks/nix-lint.nix --no-link --print-build-logs

# Offline regression tests for Nu helpers, evaluation checks, and update scripts.
script-check:
    nix build --file checks/nu-scripts.nix --no-link --print-build-logs

# Exercise the patched nh CLI without building or activating a NixOS system.
nh-check:
    nix build --file checks/nh.nix --no-link --print-build-logs

# Scan the running generation; detailed reports use the existing age recipient.
security-scan output="/tmp/nix-security-report":
    nix run --impure --expr 'import ./packages/security {}' . -- /run/current-system --scope deployed --output {{ quote(output) }}

# Rescan a previously decrypted CycloneDX inventory with current advisories.
security-rescan sbom output="/tmp/nix-security-rescan":
    nix run --impure --expr 'import ./packages/security {}' . -- {{ quote(sbom) }} --sbom --scope inventory --output {{ quote(output) }}

# Verify security report privacy, failure handling, and Actions definitions.
security-check:
    nix build --file checks/security.nix --no-link --print-build-logs

build-iso:
    nix run "nixpkgs#nixos-generators" -- --format iso --flake ".#minimal"
