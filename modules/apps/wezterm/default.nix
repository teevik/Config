{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.wezterm;
in
{
  options.teevik.apps.wezterm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable wezterm
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      programs.wezterm = {
        enable = true;

        extraConfig = ''
          return {
            font = wezterm.font("JetBrainsMono Nerd Font"),
            font_size = 13.0,

            hide_tab_bar_if_only_one_tab = true,
            scrollback_lines = 10000,

      	    window_background_opacity = 0.6,
            color_scheme = "Catppuccin Mocha",

            underline_thickness = 3,
            underline_position = -4,

            alternate_buffer_wheel_scroll_speed = 1,
          }
        '';
      };
    };
  };
}
