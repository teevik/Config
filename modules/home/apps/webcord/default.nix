{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.webcord;
in
{
  options.teevik.apps.webcord = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable webcord
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      webcord-vencord
    ];

    xdg.configFile =
      let
        theme = pkgs.fetchFromGitHub {
          owner = "teevik";
          repo = "EverforestDiscord";
          rev = "98bfbdff4f51c1d2b13a9148d25404f698bda622";
          hash = "sha256-iqWCQrj+z92WqrGeTEFvxc0N2jELazx8JiB305ChSkI=";
        };
      in
      {
        "WebCord/Themes/theme".source = "${theme}/everforest.theme.css";
      };
  };
}
# 
