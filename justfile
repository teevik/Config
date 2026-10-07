# Install without rebooting; stage private keys before the first boot.
[positional-arguments]
install TARGET-IP HOST:
    @bash scripts/provision.sh install "$@"

# After booting the installed system, transfer this checkout and fix ownership.
[positional-arguments]
provision TARGET-IP:
    @bash scripts/provision.sh provision "$@"

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

[positional-arguments]
update *args:
    @nix run --impure --expr 'import ./packages/nu-scripts {}' . -- packages/update.nu "$@"
