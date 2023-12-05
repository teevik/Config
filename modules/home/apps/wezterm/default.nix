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
    programs.wezterm = {
      enable = true;

      colorSchemes.teevik = with config.teevik.theme.colors.withHashtag; {
        ansi = [ base00 base08 base0A base0D base0E base0C base0C base05 ];
        brights = [ base03 base08 base0B base0A base0D base0E base0C base07 ];
        background = base00;
        cursor_bg = base05;
        cursor_fg = base05;
        compose_cursor = base06;
        foreground = base05;
        scrollbar_thumb = base01;
        selection_bg = base05;
        selection_fg = base00;
        split = base03;
        visual_bell = base09;
        tab_bar = {
          background = base01;
          inactive_tab_edge = base01;
          active_tab = {
            bg_color = base03;
            fg_color = base05;
          };
          inactive_tab = {
            bg_color = base00;
            fg_color = base05;
          };
          inactive_tab_hover = {
            bg_color = base05;
            fg_color = base00;
          };
          new_tab = {
            bg_color = base00;
            fg_color = base05;
          };
          new_tab_hover = {
            bg_color = base05;
            fg_color = base00;
          };
        };
      };

      extraConfig = ''
        local wezterm = require("wezterm")

        wezterm.add_to_config_reload_watch_list(wezterm.config_dir)

        local config = wezterm.config_builder()

        config.color_scheme = "teevik"

        config.font = wezterm.font("JetBrainsMono Nerd Font")
        config.font_size = 13.0

        config.hide_tab_bar_if_only_one_tab = true
        config.scrollback_lines = 10000

        config.window_background_opacity = 0.7
        config.macos_window_background_blur = 70

        config.underline_thickness = 3
        config.underline_position = -4

        config.alternate_buffer_wheel_scroll_speed = 1

        config.window_close_confirmation = "NeverPrompt"

        return config
      '';
    };
  };
}
