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

    opacity = mkOption {
      type = types.float;
      default = 0;
      description = "Background opacity";
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
        background_opacity = builtins.toJSON cfg.opacity;
        dynamic_background_opacity = "yes";
        background_blur = 65;
        window_padding_width = 10;
        allow_remote_control = "yes";
      };

      keybindings = {
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+n" = "new_os_window_with_cwd";
      };
    };
  };
}
