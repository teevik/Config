{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.just;
in
{
  options.teevik.apps.just = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable just
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      just
    ];

  };
}
