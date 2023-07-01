{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.pycharm;
in
{
  options.teevik.apps.pycharm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable pycharm
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jetbrains.pycharm-professional
    ];
  };
}
