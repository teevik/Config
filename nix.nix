{ inputs, pkgs, lib, ... }:
let
  inherit (lib) mkIf;
  isArm = pkgs.system == "aarch64-linux";
in
{
  nix = {
    package = mkIf (!isArm) inputs.nix-super.packages.${pkgs.system}.default;

    settings = {
      trusted-users = [
        "root"
        "teevik"
      ];

      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;

      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org/"
        "https://devenv.cachix.org/"
        "https://nyx.chaotic.cx"
        "https://viperml.cachix.org"
        "https://neovim-flake.cachix.org/"
        "https://cache.privatevoid.net"
        "https://jakestanger.cachix.org"
      ];

      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
        "neovim-flake.cachix.org-1:iyQ6lHFhnB5UkVpxhQqLJbneWBTzM8LBYOFPLNH4qZw="
        "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
        "jakestanger.cachix.org-1:VWJE7AWNe5/KOEvCQRxoE8UsI2Xs2nHULJ7TEjYm7mM="
      ];
    };

    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 30d";
    # };

    registry.default.flake = inputs.nixpkgs;

    # flake-utils-plus
    generateRegistryFromInputs = true;
    generateNixPathFromInputs = true;
    linkInputs = true;
  };
}
