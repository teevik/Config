# Install HOST on a machine and reboot it; it boots with this checkout and keys.
[positional-arguments]
install TARGET-IP HOST:
    @nix run --impure --expr 'import ./packages/nu-scripts { tools = [ "nixos-anywhere" ]; }' . -- scripts/install.nu "$@"

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

# Daily: refresh agents, T3 Code, Roc and all inputs but nixpkgs, then apply
update-apps: (refresh "--apps" "--no-build") apply

# Full: refresh everything including nixpkgs, then apply; may need a reboot
update: (refresh "--no-build") apply

# Refresh sources without applying them (options: packages/update.nu)
[positional-arguments]
refresh *args:
    @nix run --impure --expr 'import ./packages/nu-scripts {}' . -- packages/update.nu "$@"

# Build this host, then switch, or stage for next boot if the kernel changed
apply:
    @nix run --impure --expr 'import ./packages/nu-scripts {}' . -- scripts/apply.nu

# Deploy the homelab; add --override-input homelab PATH to test a local checkout
[positional-arguments]
deploy-homelab *args:
    nixos-rebuild switch --flake .#homelab --target-host homelab --sudo --no-reexec "$@"
