{ inputs, pkgs, lib, ... }:
let
  inherit (lib) mkIf;
  isArm = pkgs.system == "aarch64-linux" || pkgs.system == "aarch64-darwin";
in
{
  home-manager.backupFileExtension = "bak";

  nix = {
    package = mkIf (!isArm) (inputs.nix-super.packages.${pkgs.system}.default);

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
        # high priority since it's almost always used
        "https://cache.nixos.org?priority=10"

        "https://teevik.cachix.org"
        # "https://cache.privatevoid.net"
        "https://hyprland.cachix.org"
        # "https://nix-community.cachix.org/"
        # "https://devenv.cachix.org/"
        # "https://viperml.cachix.org"
        # "https://jakestanger.cachix.org"
        # "https://helix.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

        "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
        # "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        # "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
        # "jakestanger.cachix.org-1:VWJE7AWNe5/KOEvCQRxoE8UsI2Xs2nHULJ7TEjYm7mM="
        # "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    };

    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 30d";
    # };

    registry.default.flake = inputs.nixpkgs;
    registry.teevik.flake = inputs.self;

    # flake-utils-plus
    generateRegistryFromInputs = true;
    generateNixPathFromInputs = true;
    linkInputs = true;
  };
}
