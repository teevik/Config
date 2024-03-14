{ pkgs, config, lib, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.tealdeer;
in
{
  options.teevik.apps.tealdeer = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tealdeer
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.tealdeer = {
      enable = true;
      settings = {
        updates.auto_update = true;
      };
    };
  };
}
