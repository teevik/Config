{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.bat;
in
{
  options.teevik.apps.bat = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable bat
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bat
    ];
  };
}
