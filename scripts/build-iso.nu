#!/usr/bin/env nu

nix run "nixpkgs#nixos-generators" -- --format iso --flake .#minimal