#!/usr/bin/env nu

def main [ip: string, flake: string, hardwarePath: string] {
  # Install NixOS on a remote machine
  nix run github:nix-community/nixos-anywhere -- --phases kexec,disko,install --generate-hardware-config nixos-generate-config $hardwarePath --flake $flake root@($ip)

  # Copy ssh keys over
  ssh root@{{TARGET-IP}} "mkdir /mnt/home/teevik/.ssh"
  scp /home/teevik/.ssh/id_rsa root@{{TARGET-IP}}:/mnt/home/teevik/.ssh/id_rsa
  scp /home/teevik/.ssh/id_rsa.pub root@{{TARGET-IP}}:/mnt/home/teevik/.ssh/id_rsa.pub

  # Clone config repo
  ssh root@{{TARGET-IP}} "mkdir /mnt/home/teevik/Documents"
  ssh teevik@{{TARGET-IP}} "git clone https://github.com/teevik/Config.git /mnt/home/teevik/Documents/Config"
  ssh teevik@{{TARGET-IP}} "cd /mnt/home/teevik/Documents/Config && git remote set-url origin git@github.com:teevik/Config.git"
}