{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.flyctl;
in
{
  options.teevik.apps.flyctl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable flyctl
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      flyctl
    ];
  };
}
