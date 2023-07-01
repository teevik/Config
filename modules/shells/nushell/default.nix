{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.shells.nushell;
in
{
  options.teevik.shells.nushell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nushell
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.nushell.enable = true;
    };
  };
}
