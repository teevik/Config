{ pkgs, perSystem, ... }: {
  home.packages = [
    perSystem.marble.astal
    perSystem.marble.marble
    perSystem.marble.screenrecord
  ];

  systemd.user.services.marble = {

    Unit = {
      Description =
        "Marble Shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };

    Service = {
      ExecStart = "${perSystem.marble.marble}/bin/marble";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      KillMode = "mixed";
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  xdg.configFile."marble/theme.json".text = builtins.toJSON {
    "dark.primary" = "#cba6f7";
    "dark.error" = "#e55f86";
    "dark.success" = "#00D787";
    "dark.bg" = "#171717";
    "dark.fg" = "#eeeeee";
    "dark.widget" = "#eeeeee";
    "dark.border" = "#eeeeee";
    # "light.primary" = "#8861dd";
    # "light.error" = "#b13558";
    # "light.success" = "#009e49";
    # "light.bg" = "#fffffa";
    # "light.fg" = "#080808";
    # "light.widget" = "#080808";
    # "light.border" = "#080808";
    "blur" = 50;
    "scheme" = "dark";
    "widget.opacity" = 94;
    "border.width" = 1;
    "border.opacity" = 100;
    "shadows" = false;
    "padding" = 9;
    "spacing" = 9;
    "radius" = 9;
    "font" = "Ubuntu Nerd Font 14";
    # "hyprland.enable" = false;
    # "hyprland.inactiveBorder.dark" = "#282828";
    # "hyprland.inactiveBorder.light" = "#181818";
    # "hyprland.gapsMultiplier" = 2.2;
    # "swww.enable" = false;
    # "swww.args" = "--transition-type fade";
    # "tmux.enable" = false;
    # "tmux.cmd" = "tmux set @main_accent \"{hex}\"";
    "gsettings.enable" = true;
  };

  xdg.configFile."marble/bar.json".text = builtins.toJSON {
    "bold" = true;
    "position" = "top";
    "corners" = "md";
    "transparent" = false;
    "layout.start" = [
      "workspaces"
      "spacer"
      "messages"
    ];
    "layout.center" = [
      "date"
    ];
    "layout.end" = [
      "media"
      "spacer"
      "systray"
      "screenrecord"
      "system"
      "battery"
      "powermenu"
    ];
    "launcher.suggested" = false;
    "launcher.flat" = true;
    "launcher.icon" = "nix-snowflake";
    "launcher.label" = "Applications";
    "launcher.action" = "astal -t launcher";
    "date.flat" = true;
    "date.format" = "%H:%M - %A %e.";
    "date.action" = "astal eval \"launcher('cal')\"";
    "battery.suggested" = true;
    "battery.flat" = true;
    "battery.bar" = "regular";
    "battery.percentage" = true;
    "battery.low" = 30;
    "battery.size" = "md";
    "workspaces.flat" = true;
    "workspaces.workspaces" = 7;
    "workspaces.action" = "astal eval \"launcher('h')\"";
    "taskbar.flat" = true;
    "taskbar.monochrome" = true;
    "messages.flat" = true;
    "messages.action" = "astal eval \"launcher('n')\"";
    "systray.flat" = true;
    "systray.ignore" = [
      "KDE Connect Indicator"
      "spotify-client"
    ];
    "media.flat" = true;
    "media.monochrome" = true;
    "media.preferred" = "spotify";
    "media.direction" = "right";
    "media.format" = "{artist} - {title}";
    "media.maxChars" = 40;
    "media.timeout" = 5000;
    "powermenu.suggested" = true;
    "powermenu.flat" = true;
    "powermenu.action" = "astal -t powermenu";
    "systemIndicators.flat" = true;
    "systemIndicators.action" = "astal eval \"launcher('a')\"";
  };

  xdg.configFile."marble/substitutes.json".text = builtins.toJSON {
    "audio-headset-bluetooth-symbolic" = "audio-headset-symbolic";
    # "external-link-symbolic" = "emblem-symbolic-link";
  };
}
