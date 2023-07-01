{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.trashy;
in
{
  options.teevik.apps.trashy = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable trashy
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      trashy
    ];
  };
}
