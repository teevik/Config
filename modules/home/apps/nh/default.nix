{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nh;
in
{
  options.teevik.apps.nh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nh
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.nh ];
    home.sessionVariables.FLAKE = "${config.home.homeDirectory}/Documents/Config";
  };
}
