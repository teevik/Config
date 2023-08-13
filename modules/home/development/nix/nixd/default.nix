{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.nix.nixd;
in
{
  options.teevik.development.nix.nixd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nixd
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixd
    ];
  };
}
