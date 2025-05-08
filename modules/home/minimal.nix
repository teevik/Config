{
  inputs,
  pkgs,
  perSystem,
  lib,
  ...
}:
{
  programs.man.generateCaches = false;
  systemd.user.startServices = "sd-switch";

  # TODO shared with home
  nixpkgs.config = {
    allowUnfree = true;
  };

  nix = {
    package = pkgs.nixVersions.nix_2_28;
    # package = pkgs.nix;
    # package = perSystem.self.lix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      trusted-users = [
        "root"
        "teevik"
      ];

      substituters = [
        "https://cache.nixos.org?priority=10"
        "https://teevik.cachix.org"
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    registry = {
      default.flake = inputs.nixpkgs;
      default-flake.flake = inputs.nixpkgs;
      nixpkgs.flake = lib.mkForce inputs.nixpkgs;
      teevik.flake = inputs.self;
      unstable.flake = inputs.unstable;
    };
  };
}
