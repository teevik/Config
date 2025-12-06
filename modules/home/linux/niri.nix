{
  inputs,
  config,
  pkgs,
  perSystem,
  ...
}:
let
  inherit (config.teevik.theme) borderColor cursorTheme colors;

  # Applications
  copyHistory = pkgs.writeShellScript "copy-history" ''
    cliphist list | tofi --prompt-text "Copy" | cliphist decode | wl-copy
  '';
  terminal = "kitty";
  menu = [
    "tofi-drun"
    "--drun-launch=true"
  ];
  browser = "firefox";
  files = "nautilus";
  editor = "code";
  settings = [
    "env"
    "XDG_CURRENT_DESKTOP=gnome"
    "gnome-control-center"
  ];

  # List of apps that should float
  floatingApps = [
    "confirm"
    "blueman"
    "org.gnome.PowerStats"
    "yad"
    "nm-connection-editor"
    "pavucontrol"
    "xfce-polkit"
    "kvantummanager"
    "qt5ct"
    "VirtualBox Manager"
    "qemu"
    "Qemu-system-x86_64"
    "1Password"
    "org.gnome.Calculator"
    "org.gnome.Nautilus"
    "blueberry.py"
    "org.gnome.Settings"
    "org.gnome.design.Palette"
    "Color Picker"
    "xdg-desktop-portal"
    "xdg-desktop-portal-gnome"
    "xdg-desktop-portal-gtk"
    "de.haeckerfelix.Fragments"
  ];

  # Generate window rules for floating apps
  floatingWindowRules = map (appId: {
    matches = [ { app-id = "^${appId}$"; } ];
    open-floating = true;
  }) floatingApps;

  openScratch = app: "nscratch --multi-monitor --app-id ${app} --spawn ${app}";
in
{
  config = {
    home.packages = [
      cursorTheme.package
      perSystem.niri-scratchpad.default
    ];

    home.sessionVariables = {
      XCURSOR_THEME = cursorTheme.name;
      # XCURSOR_SIZE = builtins.toString cursorSize;
    };

    programs.niri = {
      settings = {
        # Startup commands
        spawn-at-startup = [
          { sh = "systemctl restart --user marble.service swaybg.service kanshi.service"; }
        ];

        outputs."Samsung Electric Company Odyssey G85SB H1AK500000".focus-at-startup = true;

        # Cursor settings
        cursor = {
          theme = cursorTheme.name;
          # size = cursorSize;
          hide-after-inactive-ms = 10000; # 10 seconds
          hide-when-typing = true;
        };

        # Input settings
        input = {
          keyboard = {
            xkb = {
              layout = "us,no";
              options = "grp:alt_shift_toggle,caps:escape";
            };
          };

          touchpad = {
            tap = true;
            natural-scroll = true;
            dwt = false; # disable while typing = false
          };

          mouse = {
            accel-speed = 0.0;
          };

          focus-follows-mouse.enable = true;
        };

        # Clipboard settings
        clipboard.disable-primary = true; # Equivalent to middle_click_paste = false

        # Prefer server-side decorations
        prefer-no-csd = true;

        workspaces."scratch" = {

        };

        # Layout settings
        layout = {
          always-center-single-column = true;
          gaps = 12; # Average of gaps_in (8) and gaps_out (12)

          # Focus ring (similar to border)
          focus-ring = {
            enable = true;
            width = 2;
            active.color = "#${borderColor}";
            inactive.color = "#${borderColor}30";
          };

          # Border (disabled, using focus ring instead)
          border.enable = false;

          # Shadow settings
          shadow = {
            enable = true;
            softness = 50;
            offset = {
              x = 0;
              y = 5;
            };
            color = "#1a1a1a1a";
          };

          # Default column width (similar to dwindle behavior)
          default-column-width = {
            proportion = 0.5;
          };

          # Preset column widths for cycling
          preset-column-widths = [
            { proportion = 1.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 1.0 / 4.0; }
          ];

          # Preset window heights
          preset-window-heights = [
            { proportion = 1.0 / 3.0; }
            { proportion = 0.5; }
            { proportion = 2.0 / 3.0; }
            { proportion = 1.0; }
          ];
        };

        overview = {
          backdrop-color = colors.withHashtag.base00;

          workspace-shadow = {
            softness = 50;
            spread = 20;
            offset = {
              x = 0;
              y = 10;
            };
            color = "#0004";
          };
        };

        # Animations (similar to hyprland bezier animations)
        animations = {
          enable = true;

          window-open.kind = {
            easing = {
              duration-ms = 200;
              curve = "ease-out-expo";
            };
          };

          window-close.kind = {
            easing = {
              duration-ms = 200;
              curve = "ease-out-expo";
            };
          };

          horizontal-view-movement.kind = {
            easing = {
              duration-ms = 200;
              curve = "ease-out-expo";
            };
          };

          workspace-switch.kind = {
            easing = {
              duration-ms = 250;
              curve = "ease-out-expo";
            };
          };
        };

        # Window rules for floating apps
        window-rules = floatingWindowRules ++ [
          # Suppress maximize for libreoffice
          {
            matches = [ { app-id = "^libreoffice.*$"; } ];
            open-maximized = false;
          }
          {
            geometry-corner-radius = {
              bottom-left = 4.0;
              bottom-right = 4.0;
              top-left = 4.0;
              top-right = 4.0;
            };
            clip-to-geometry = true;
            draw-border-with-background = false;
          }
          {
            matches = [ { app-id = "^spotify|vesktop$"; } ];
            open-on-workspace = "scratch";
            open-floating = true;
            open-focused = false;
            default-column-width.proportion = 0.618;
            default-window-height.proportion = 0.75;
          }
        ];

        # Keybindings
        binds = {
          # Terminal
          "Mod+Shift+Return".action.spawn = terminal;
          "Mod+Return".action.spawn = terminal;

          # Apps
          "Mod+D".action.spawn = menu;
          "Mod+W".action.spawn = browser;
          "Mod+F".action.spawn = files;
          "Mod+E".action.spawn = editor;
          "Mod+S".action.spawn = settings;
          "Mod+V".action.spawn = "${copyHistory}";
          "Mod+M".action.spawn-sh = openScratch "spotify";
          "Mod+Backspace".action.spawn-sh = openScratch "vesktop";

          # Screenshot
          "Print".action.screenshot-screen = { };
          "Alt+Print".action.screenshot-window = { };
          "Ctrl+Print".action.screenshot = { };

          # Window management
          "Mod+Q".action.close-window = { };
          "Ctrl+Alt+Delete".action.quit = { };
          "Mod+A".action.fullscreen-window = { };
          "Mod+Space".action.toggle-window-floating = { };
          "Mod+Shift+Q".action.spawn = [ "poweroff" ];

          # Focus (niri uses column-based navigation)
          "Mod+Left".action.focus-column-left = { };
          "Mod+Right".action.focus-column-right = { };
          "Mod+Up".action.focus-window-up = { };
          "Mod+Down".action.focus-window-down = { };

          # Move windows
          "Mod+Shift+Left".action.move-column-left = { };
          "Mod+Shift+Right".action.move-column-right = { };
          "Mod+Shift+Up".action.move-window-up = { };
          "Mod+Shift+Down".action.move-window-down = { };

          "Mod+Comma".action.consume-or-expel-window-left = { };
          "Mod+Period".action.consume-or-expel-window-right = { };
          "Mod+C".action.center-column = { };

          # Resize
          "Mod+Ctrl+Left".action.set-column-width = "-10%";
          "Mod+Ctrl+Right".action.set-column-width = "+10%";
          "Mod+Ctrl+Up".action.set-window-height = "-10%";
          "Mod+Ctrl+Down".action.set-window-height = "+10%";

          # Column width presets
          "Mod+Tab".action.switch-preset-column-width = { };
          "Mod+Shift+R".action.switch-preset-window-height = { };
          "Mod+Ctrl+F".action.maximize-column = { };

          # Consume/expel windows (niri-specific)
          "Mod+BracketLeft".action.consume-window-into-column = { };
          "Mod+BracketRight".action.expel-window-from-column = { };

          # Workspaces
          "Mod+1".action.focus-workspace = 2;
          "Mod+2".action.focus-workspace = 3;
          "Mod+3".action.focus-workspace = 4;
          "Mod+4".action.focus-workspace = 5;
          "Mod+5".action.focus-workspace = 6;
          "Mod+6".action.focus-workspace = 7;
          "Mod+7".action.focus-workspace = 8;
          "Mod+8".action.focus-workspace = 9;
          "Mod+9".action.focus-workspace = 10;
          "Mod+0".action.focus-workspace = 11;

          # Move to workspace
          "Mod+Shift+1".action.move-column-to-workspace = 2;
          "Mod+Shift+2".action.move-column-to-workspace = 3;
          "Mod+Shift+3".action.move-column-to-workspace = 4;
          "Mod+Shift+4".action.move-column-to-workspace = 5;
          "Mod+Shift+5".action.move-column-to-workspace = 6;
          "Mod+Shift+6".action.move-column-to-workspace = 7;
          "Mod+Shift+7".action.move-column-to-workspace = 8;
          "Mod+Shift+8".action.move-column-to-workspace = 9;
          "Mod+Shift+9".action.move-column-to-workspace = 10;
          "Mod+Shift+0".action.move-column-to-workspace = 11;

          # Workspace navigation
          "Mod+Page_Down".action.focus-workspace-down = { };
          "Mod+Page_Up".action.focus-workspace-up = { };
          "Mod+Shift+Page_Down".action.move-column-to-workspace-down = { };
          "Mod+Shift+Page_Up".action.move-column-to-workspace-up = { };

          # Mouse scroll workspaces
          "Alt+WheelScrollDown".action.focus-column-left = { };
          "Alt+WheelScrollUp".action.focus-column-right = { };
          "Mod+WheelScrollDown".action.focus-workspace-down = { };
          "Mod+WheelScrollUp".action.focus-workspace-up = { };

          # Function keys
          "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl s --min-value=10 --exponent=2 7%+";
          "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl s --min-value=10 --exponent=2 7%-";
          "XF86AudioRaiseVolume".action.spawn-sh = "pulsemixer --change-volume +10";
          "XF86AudioLowerVolume".action.spawn-sh = "pulsemixer --change-volume -10";
          "XF86AudioMute".action.spawn-sh = "pulsemixer --toggle-mute";
          "XF86AudioNext".action.spawn-sh = "playerctl next";
          "XF86AudioPrev".action.spawn-sh = "playerctl previous";
          "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
          "XF86AudioStop".action.spawn-sh = "playerctl stop";

          # Overview (niri-specific)
          "Alt+Tab".action.toggle-overview = { };

          # Tabbed columns (niri-specific)
          "Mod+T".action.toggle-column-tabbed-display = { };
        };

        # Hotkey overlay settings
        hotkey-overlay.skip-at-startup = true;
      };
    };
  };
}
