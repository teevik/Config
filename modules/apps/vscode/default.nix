{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.vscode;
in
{
  options.teevik.apps.vscode = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable vscode
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.vscode = {
        enable = true;
      };
    };
  };
}
