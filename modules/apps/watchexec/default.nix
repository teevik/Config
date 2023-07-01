{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.watchexec;
in
{
  options.teevik.apps.watchexec = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable watchexec
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      watchexec
    ];
  };
}
