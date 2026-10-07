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

[positional-arguments]
update *args:
    @nix run --impure --expr 'import ./packages/nu-scripts {}' . -- packages/update.nu "$@"
