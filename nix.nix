{ inputs, pkgs, lib, ... }:
let
  inherit (lib) mkIf;
  isArm = pkgs.system == "aarch64-linux" || pkgs.system == "aarch64-darwin";
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
        # "https://nix-community.cachix.org/"
        # "https://devenv.cachix.org/"
        # "https://viperml.cachix.org"
        "https://cache.privatevoid.net"
        # "https://jakestanger.cachix.org"
        # "https://anyrun.cachix.org"
        # "https://nix-gaming.cachix.org"
        # "https://helix.cachix.org"
      ];

      trusted-public-keys = [
        # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        # "viperml.cachix.org-1:qZhKBMTfmcLL+OG6fj/hzsMEedgKvZVFRRAhq7j8Vh8="
        "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg="
        # "jakestanger.cachix.org-1:VWJE7AWNe5/KOEvCQRxoE8UsI2Xs2nHULJ7TEjYm7mM="
        # "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
        # "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
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
