{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.odin;
in
{
  options.teevik.development.odin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable odin
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # TODO use normal odin once this exists https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/by-name/od/odin/package.nix
      teevik.odin
      teevik.ols
      # (ols.override { odin = teevik.odin; })
    ];
  };
}
