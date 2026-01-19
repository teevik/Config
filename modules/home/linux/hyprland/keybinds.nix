{
  perSystem,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  enabled = osConfig.programs.hyprland.enable;

  hyprland-scratchpad-package = perSystem.hyprland-scratchpad.default;
  hyprland-scratchpad = lib.getExe hyprland-scratchpad-package;
  terminal = "kitty";
  menu = "tofi-drun --drun-launch=true";
  browser = "firefox";
  discord = "vesktop";
  spotify = "spotify";
  files = "nautilus";
  editor = "code";
  settings = "env XDG_CURRENT_DESKTOP=gnome gnome-control-center";
  # network = "iwmenu -m custom --menu-command \"tofi --prompt-text select:\"";

  # XDG_SCREENSHOTS_DIR = "/home/teevik/Pictures/Screenshots";
  XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
  keyBinds = {
    # Terminal
    bind."SUPER_SHIFT, Return" = "exec, ${terminal}";
    bind."SUPER, Return" =
      "exec, ${hyprland-scratchpad} toggle-exec --name terminal --exec '${terminal}'";

    # Apps
    bind."SUPER, D" = "exec, ${menu}";
    bind."SUPER, W" = "exec, ${browser}";
    bind."SUPER, F" = "exec, ${files}";
    bind."SUPER, E" = "exec, ${editor}";
    bind."SUPER, Backspace" =
      "exec, ${hyprland-scratchpad} toggle-exec --name discord --exec '${discord}'";
    bind."SUPER, M" = "exec, ${hyprland-scratchpad} toggle-exec --name spotify --exec '${spotify}'";
    bind."SUPER, S" = "exec, ${hyprland-scratchpad} toggle-exec --name settings --exec '${settings}'";

    # Screenshot
    bind.", Print" =
      "exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} grimblast --notify copysave output";
    bind."CTRL, Print" =
      "exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} grimblast --notify copysave area";

    # Hyprland
    bind."SUPER, Q" = "killactive,";
    bind."CTRLALT, Delete" = "exit,";
    bind."SUPER, A" = "fullscreen,";
    bind."SUPER, Space" = "togglefloating,";
    bind."SUPER_SHIFT, Q" = "exec, poweroff";

    bind."SUPER, L" = "exec, hyprctl keyword general:layout \"dwindle\"";
    bind."SUPER_SHIFT, L" = "exec, hyprctl keyword general:layout \"master\"";

    # Function keys
    binde.",XF86MonBrightnessUp" = "exec, brightnessctl s --min-value=10 --exponent=2 7%+";
    binde.",XF86MonBrightnessDown" = "exec, brightnessctl s --min-value=10 --exponent=2 7%-";
    binde.",XF86AudioRaiseVolume" = "exec, pulsemixer --change-volume +10";
    binde.",XF86AudioLowerVolume" = "exec, pulsemixer --change-volume -10";
    bind.",XF86AudioMute" = "exec, pulsemixer --toggle-mute";
    bind.",XF86AudioNext" = "exec, playerctl next";
    bind.",XF86AudioPrev" = "exec, playerctl previous";
    bind.",XF86AudioPlay" = "exec, playerctl play-pause";
    bind.",XF86AudioStop" = "exec, playerctl stop";

    # Scroll through existing workspaces with SUPER + scroll
    bind."SUPER, mouse_down" = "split-cycleworkspaces, +1";
    bind."SUPER, mouse_up" = "split-cycleworkspaces, -1";

    # Use mouse scroll left and right
    bind.", mouse_right" = "split-cycleworkspaces, +1";
    bind.", mouse_left" = "split-cycleworkspaces, -1";

    # Focus
    bind."SUPER,left" = "movefocus, l";
    bind."SUPER,right" = "movefocus, r";
    bind."SUPER,up" = "movefocus, u";
    bind."SUPER,down" = "movefocus, d";

    # Move
    bind."SUPERSHIFT,left" = "movewindow,l";
    bind."SUPERSHIFT,right" = "movewindow,r";
    bind."SUPERSHIFT,up" = "movewindow,u";
    bind."SUPERSHIFT,down" = "movewindow,d";
    bindm."SUPER,mouse:272" = "movewindow";
    bindm."SUPERSHIFT,mouse:272" = "resizewindow";
    bind."SUPER,mouse:273" = "togglesplit";

    # Resize
    bind."SUPERCTRL,left" = "resizeactive,-20 0";
    bind."SUPERCTRL,right" = "resizeactive,20 0";
    bind."SUPERCTRL,up" = "resizeactive,0 -20";
    bind."SUPERCTRL,down" = "resizeactive,0 20";

    # Workspaces
    bind."SUPER,1" = "split-workspace,1";
    bind."SUPER,2" = "split-workspace,2";
    bind."SUPER,3" = "split-workspace,3";
    bind."SUPER,4" = "split-workspace,4";
    bind."SUPER,5" = "split-workspace,5";
    bind."SUPER,6" = "split-workspace,6";
    bind."SUPER,7" = "split-workspace,7";
    bind."SUPER,8" = "split-workspace,8";
    bind."SUPER,9" = "split-workspace,9";
    bind."SUPER,0" = "split-workspace,10";

    # Send to Workspaces
    bind."SUPER_SHIFT,1" = "split-movetoworkspacesilent,1";
    bind."SUPER_SHIFT,2" = "split-movetoworkspacesilent,2";
    bind."SUPER_SHIFT,3" = "split-movetoworkspacesilent,3";
    bind."SUPER_SHIFT,4" = "split-movetoworkspacesilent,4";
    bind."SUPER_SHIFT,5" = "split-movetoworkspacesilent,5";
    bind."SUPER_SHIFT,6" = "split-movetoworkspacesilent,6";
    bind."SUPER_SHIFT,7" = "split-movetoworkspacesilent,7";
    bind."SUPER_SHIFT,8" = "split-movetoworkspacesilent,8";
    bind."SUPER_SHIFT,9" = "split-movetoworkspacesilent,9";
    bind."SUPER_SHIFT,0" = "split-movetoworkspacesilent,10";
  };

  bindsToList =
    binds: lib.attrsets.mapAttrsToList (binding: dispatcher: "${binding}, ${dispatcher}") binds;
in
{
  config = mkIf enabled {
    home.packages = [
      hyprland-scratchpad-package
    ];

    wayland.windowManager.hyprland = {
      settings = builtins.mapAttrs (name: bindsToList) keyBinds;
    };
  };
}
