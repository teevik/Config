{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.obsidian;
in
{
  options.teevik.apps.obsidian = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable obsidian
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      obsidian
    ];
  };
}
