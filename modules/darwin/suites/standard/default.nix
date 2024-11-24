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
    # https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
    system.activationScripts.postUserActivation.text = ''
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    system.defaults = {
      # Whether to automatically rearrange spaces
      dock = {
        autohide = true;
        mru-spaces = false;
      };

      NSGlobalDomain = {
        "com.apple.mouse.tapBehavior" = 1;
      };

      CustomUserPreferences = {
        NSGlobalDomain.WebKitDeveloperExtras = true;
      };

      trackpad = {
        Dragging = true;
        Clicking = true;
      };
    };

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

    # services.yabai = {
    #   enable = true;
    #   enableScriptingAddition = true;

    #   config = {
    #     mouse_modifier = "alt";

    #     layout = "bsp";
    #     focus_follows_mouse = "autoraise";
    #     window_topmost = true;
    #     window_placement = "second_child";

    #     top_padding = 8;
    #     bottom_padding = 8;
    #     left_padding = 8;
    #     right_padding = 8;

    #     window_gap = 12;
    #   };

    #   extraConfig = ''
    #     yabai -m rule --add app="^System Preferences$" manage=off
    #     yabai -m rule --add app="^Finder$" manage=off
    #     yabai -m rule --add app="^Calculator$" manage=off
    #     yabai -m rule --add app="^Disk Utility$" manage=off
    #     yabai -m rule --add app="^Activity Monitor$" manage=off
    #     yabai -m rule --add app="^Installer$" manage=off
    #     yabai -m rule --add app="^System Information$" manage=off
    #   '';
    # };

    # services.skhd = {
    #   enable = true;
    #   skhdConfig = ''
    #     alt - a : yabai -m window --toggle zoom-fullscreen
    #     alt - space : yabai -m window --toggle float && \
    #                   yabai -m window --grid 5:5:1:1:3:3

    #     alt - q : yabai -m window --close
    #     # alt - q: osascript -e 'tell application "System Events" to perform action "AXPress" of (first button whose subrole is "AXCloseButton") of (first window whose subrole is "AXStandardWindow") of (first process whose frontmost is true)'

    #     alt - d : open -a Launchpad

    #     alt - return : open -na kitty
    #     alt + shift - return : open -na kitty

    #     alt - w : open -na Safari
    #     alt - f : open ~
    #     alt - e : code
    #     alt - backspace : Discord
    #     alt - m : open -a Spotify

    #     alt + cmd - left : yabai -m window --resize left:-40:0 --resize right:-40:0
    #     alt + cmd - right : yabai -m window --resize right:40:0 --resize left:40:0
    #     alt + cmd - up : yabai -m window --resize top:0:-40 --resize bottom:0:-40
    #     alt + cmd - down : yabai -m window --resize bottom:0:40 --resize top:0:40

    #     alt - 1 : yabai -m space --focus 1
    #     alt - 2 : yabai -m space --focus 2
    #     alt - 3 : yabai -m space --focus 3
    #     alt - 4 : yabai -m space --focus 4
    #     alt - 5 : yabai -m space --focus 5
    #     alt - 6 : yabai -m space --focus 6
    #     alt - 7 : yabai -m space --focus 7
    #     alt - 8 : yabai -m space --focus 8
    #     alt - 9 : yabai -m space --focus 9
    #     alt - 0 : yabai -m space --focus 10

    #     alt + shift - 1 : yabai -m window --space 1
    #     alt + shift - 2 : yabai -m window --space 2
    #     alt + shift - 3 : yabai -m window --space 3
    #     alt + shift - 4 : yabai -m window --space 4
    #     alt + shift - 5 : yabai -m window --space 5
    #     alt + shift - 6 : yabai -m window --space 6
    #     alt + shift - 7 : yabai -m window --space 7
    #     alt + shift - 8 : yabai -m window --space 8
    #     alt + shift - 9 : yabai -m window --space 9
    #     alt + shift - 0 : yabai -m window --space 10

    #     alt - up : yabai -m window --focus north
    #     alt - right : yabai -m window --focus east
    #     alt - down : yabai -m window --focus south
    #     alt - left : yabai -m window --focus west

    #     alt + shift - up : yabai -m window --warp north
    #     alt + shift - right : yabai -m window --warp east
    #     alt + shift - down : yabai -m window --warp south
    #     alt + shift - left : yabai -m window --warp west
    #   '';
    # };

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
      # skhd
    ];
  };
}
