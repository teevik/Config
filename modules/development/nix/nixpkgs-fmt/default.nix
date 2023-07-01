{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.nix.nixpkgs-fmt;
in
{
  options.teevik.development.nix.nixpkgs-fmt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nixpkgs-fmt
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nixpkgs-fmt
    ];
  };
}
