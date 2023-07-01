{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.sd;
in
{
  options.teevik.apps.sd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable sd
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sd
    ];
  };
}
