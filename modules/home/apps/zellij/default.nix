{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.zellij;
in
{
  options.teevik.apps.zellij = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable zellij
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;

      settings = {
        theme = "catppuccin-mocha";

        themes = {
          catppuccin-mocha = {
            bg = "#585b70"; # Surface2
            fg = "#cdd6f4";
            red = "#f38ba8";
            green = "#a6e3a1";
            blue = "#89b4fa";
            yellow = "#f9e2af";
            magenta = "#f5c2e7"; # Pink
            orange = "#fab387"; # Peach
            cyan = "#89dceb"; # Sky
            black = "#181825"; # Mantle
            white = "#cdd6f4";
          };

          tokyo-night-storm = {
            fg = "#a9b1d6";
            bg = "#24283b";
            black = "#383e5a";
            red = "#f93357";
            green = "#9ece6a";
            yellow = "#e0af68";
            blue = "#7aa2f7";
            magenta = "#bb9af7";
            cyan = "#2ac3de";
            white = "#c0caf5";
            orange = "#ff9e64";
          };
        };
      };
    };
  };
}
