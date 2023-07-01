{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.clion;
in
{
  options.teevik.apps.clion = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable clion
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jetbrains.clion
    ];
  };
}
