{ pkgs
, config
, lib
, ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.standard;
in
{
  options.teevik.suites.standard = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable standard suite
      '';
    };
  };

  config = mkIf cfg.enable {
    services.nix-daemon.enable = true;

    security.pam.enableSudoTouchIdAuth = true;

    homebrew.enable = true;
    homebrew.global.brewfile = true;

    homebrew.masApps = {
      "1Password for Safari" = 1569813296;
      "Fantastical - Calendar" = 975937182;
    };

    system.keyboard.enableKeyMapping = true;
    system.keyboard.userKeyMapping =
      let
        fn = 1095216660483;
        left_control = 30064771296;
        left_option = 30064771298;
        left_command = 30064771299;
      in
      [
        {
          HIDKeyboardModifierMappingSrc = fn;
          HIDKeyboardModifierMappingDst = left_command;
        }
        {
          HIDKeyboardModifierMappingSrc = left_control;
          HIDKeyboardModifierMappingDst = left_control;
        }
        {
          HIDKeyboardModifierMappingSrc = left_option;
          HIDKeyboardModifierMappingDst = left_option;
        }
        {
          HIDKeyboardModifierMappingSrc = left_command;
          HIDKeyboardModifierMappingDst = fn;
        }
      ];

    services.yabai = {
      enable = true;
      enableScriptingAddition = true;

      config = {
        mouse_modifier = "alt";

        layout = "bsp";
        focus_follows_mouse = "autoraise";
        window_topmost = true;
        window_placement = "second_child";

        top_padding = 8;
        bottom_padding = 8;
        left_padding = 8;
        right_padding = 8;

        window_gap = 12;
      };
    };

    services.skhd = {
      enable = true;
      skhdConfig = ''
        alt - a : yabai -m window --toggle zoom-fullscreen
        alt - space : yabai -m window --toggle float

        alt - q : yabai -m window --close

        alt - return : wezterm
        alt + shift - return : wezterm

        alt - w : open -n -a Safari
      '';
      # fn - q : 
    };

    # Whether to automatically rearrange spaces
    system.defaults.dock.mru-spaces = false;

    teevik = {
      desktop = {
        fonts.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      services = {
        nix-daemon.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      git
    ];
  };
}
