{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.shells.fish;
in
{
  options.teevik.shells.fish = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fish
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.fish.enable = true;
    environment.shells = [ pkgs.fish ];
    teevik.user.extraOptions.shell = pkgs.fish;

    environment.variables.EDITOR = "hx";
  };
}
