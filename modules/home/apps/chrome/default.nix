{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.chrome;
in
{
  options.teevik.apps.chrome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable chrome
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.google-chrome = {
      enable = true;

      commandLineArgs = [ "--enable-features=TouchpadOverscrollHistoryNavigation" ];
    };
  };
}
