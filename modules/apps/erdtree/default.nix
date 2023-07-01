{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.erdtree;
in
{
  options.teevik.apps.erdtree = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable erdtree
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      erdtree
    ];
  };
}
