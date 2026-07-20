install TARGET-IP HOST:
    # Run disko and install nixos
    nix run github:numtide/nixos-anywhere -- \
      --build-on remote \
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

# Remove stowed dotfiles
unstow:
    stow -v -t ~ -D dotfiles

# Re-stow dotfiles (useful after adding new files)
restow:
    mkdir -p ~/.pi/agent
    stow -v -t ~ -R dotfiles

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

# update:
#     #!/usr/bin/env bash
#     set -euo pipefail
#     version="$(npm view '@opencode-ai/cli-linux-x64-baseline@next' version)"
#     nix run nixpkgs#nix-update -- -f packages/nix-update.nix opencode --version "$version" --build

build-iso:
    nix run "nixpkgs#nixos-generators" -- --format iso --flake ".#minimal"
