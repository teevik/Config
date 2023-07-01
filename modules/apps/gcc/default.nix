{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.gcc;
in
{
  options.teevik.apps.gcc = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gcc
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gcc
    ];

  };
}
