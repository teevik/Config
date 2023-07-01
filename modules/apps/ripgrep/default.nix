{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.ripgrep;
in
{
  options.teevik.apps.ripgrep = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable ripgrep
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ripgrep
      ripgrep-all
    ];
  };
}
