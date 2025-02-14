#!/usr/bin/env nu

def main [ip: string, flake: string, hardwarePath: string] {
  nix run github:nix-community/nixos-anywhere --phases kexec,disko,install --generate-hardware-config nixos-generate-config $hardwarePath --flake $flake root@$ip
}