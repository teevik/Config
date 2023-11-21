{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.kitty;
  inherit (config.teevik.theme) kittyTheme;
in
{
  options.teevik.apps.kitty = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable kitty
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      font.name = "JetBrainsMono Nerd Font";

      theme = kittyTheme;

      settings = {
        scrollback_fill_enlarged_window = "yes";
        scrollback_lines = 10000;
        update_check_interval = 0;
        font_size = 13;
        background_opacity = "0.5";
        dynamic_background_opacity = "yes";
        background_blur = 50;
        window_padding_width = 10;
        allow_remote_control = "yes";
      };

      #   extraConfig = ''
      #     local wezterm = require("wezterm")

      #     wezterm.add_to_config_reload_watch_list(wezterm.config_dir)

      #     local config = wezterm.config_builder()

      #     config.color_scheme = "teevik"

      #     config.font = wezterm.font("JetBrainsMono Nerd Font")
      #     config.font_size = 13.0

      #     config.hide_tab_bar_if_only_one_tab = true
      #     config.scrollback_lines = 10000

      #     config.window_background_opacity = 0.7
      #     config.macos_window_background_blur = 50

      #     config.underline_thickness = 3
      #     config.underline_position = -4

      #     config.alternate_buffer_wheel_scroll_speed = 1

      #     config.window_close_confirmation = "NeverPrompt"

      #     return config
      #   ''; 
    };
  };
}
