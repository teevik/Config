{
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  pinnedNixpkgs =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/5135c59491985879812717f4c9fea69604e7f26f.tar.gz";
        sha256 = "09qy7zv80bkd9ighsw0bdxjq70dw3qjnyvg7il1fycrsgs5x1gan";
      })
      {
        system = pkgs.stdenv.hostPlatform.system;
      };
in
{
  imports = [
    ../../shared/packages
  ];

  programs.ydotool = {
    enable = true;
    group = "input";
  };

  users.users.teevik.extraGroups = [ "input" ];

  environment.systemPackages = [
    perSystem.openconnect-sso.default
    pkgs.zoom-us
  ]
  ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
    pinnedNixpkgs.stremio
  ];

  # Nix-index database for command-not-found
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false;
}
