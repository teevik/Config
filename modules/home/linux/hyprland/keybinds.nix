{ perSystem, lib, config, ... }:
let

  hyprland-scratchpad-package = perSystem.self.hyprland-scratchpad;
  hyprland-scratchpad = lib.getExe hyprland-scratchpad-package;
  terminal = "kitty";
  menu = "tofi-drun --drun-launch=true";
  browser = "firefox";
  discord = "vesktop";
  spotify = "spotify";
  files = "nautilus";
  editor = "code";

  # XDG_SCREENSHOTS_DIR = "/home/teevik/Pictures/Screenshots";
  XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
  keyBinds = {
    # Terminal
    bind."SUPER_SHIFT, Return" = "exec, ${terminal}";
    bind."SUPER, Return" = "exec, ${hyprland-scratchpad} toggle-exec --name terminal --exec '${terminal}'";

    # Apps
    bind."SUPER, D" = "exec, ${menu}";
    bind."SUPER, W" = "exec, ${browser}";
    bind."SUPER, F" = "exec, ${files}";
    bind."SUPER, E" = "exec, ${editor}";
    bind."SUPER, Backspace" = "exec, ${hyprland-scratchpad} toggle-exec --name discord --exec '${discord}'";
    bind."SUPER, M" = "exec, ${hyprland-scratchpad} toggle-exec --name spotify --exec '${spotify}'";

    # Screenshot
    bind.", Print" = "exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} grimblast --notify copysave output";
    bind."CTRL, Print" = "exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} grimblast --notify copysave area";

    # Hyprland
    bind."SUPER, Q" = "killactive,";
    bind."CTRLALT, Delete" = "exit,";
    bind."SUPER, A" = "fullscreen,";
    bind."SUPER, Space" = "togglefloating,";
    bind."SUPER_SHIFT, Q" = "exec, poweroff";

    # Function keys
    binde.",XF86MonBrightnessUp" = "exec, light -A 10";
    binde.",XF86MonBrightnessDown" = "exec, light -U 10";
    binde.",XF86AudioRaiseVolume" = "exec, pulsemixer --change-volume +10";
    binde.",XF86AudioLowerVolume" = "exec, pulsemixer --change-volume -10";
    bind.",XF86AudioMute" = "exec, pulsemixer --toggle-mute";
    bind.",XF86AudioNext" = "exec, playerctl next";
    bind.",XF86AudioPrev" = "exec, playerctl previous";
    bind.",XF86AudioPlay" = "exec, playerctl play-pause";
    bind.",XF86AudioStop" = "exec, playerctl stop";

    # Scroll through existing workspaces with SUPER + scroll
    bind."SUPER, mouse_down" = "workspace, e+1";
    bind."SUPER, mouse_up" = "workspace, e-1";

    # Use mouse scroll left and right
    bind.", mouse_right" = "workspace, e+1";
    bind.", mouse_left" = "workspace, e-1";

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
    bind."SUPER,1" = "workspace,1";
    bind."SUPER,2" = "workspace,2";
    bind."SUPER,3" = "workspace,3";
    bind."SUPER,4" = "workspace,4";
    bind."SUPER,5" = "workspace,5";
    bind."SUPER,6" = "workspace,6";
    bind."SUPER,7" = "workspace,7";
    bind."SUPER,8" = "workspace,8";
    bind."SUPER,9" = "workspace,9";
    bind."SUPER,0" = "workspace,10";

    # Send to Workspaces
    bind."SUPER_SHIFT,1" = "movetoworkspace,1";
    bind."SUPER_SHIFT,2" = "movetoworkspace,2";
    bind."SUPER_SHIFT,3" = "movetoworkspace,3";
    bind."SUPER_SHIFT,4" = "movetoworkspace,4";
    bind."SUPER_SHIFT,5" = "movetoworkspace,5";
    bind."SUPER_SHIFT,6" = "movetoworkspace,6";
    bind."SUPER_SHIFT,7" = "movetoworkspace,7";
    bind."SUPER_SHIFT,8" = "movetoworkspace,8";
    bind."SUPER_SHIFT,9" = "movetoworkspace,9";
    bind."SUPER_SHIFT,0" = "movetoworkspace,10";
  };

  bindsToList = binds: lib.attrsets.mapAttrsToList
    (binding: dispatcher: "${binding}, ${dispatcher}")
    binds;
in
{
  home.packages = [
    hyprland-scratchpad-package
  ];

  wayland.windowManager.hyprland = {
    settings = builtins.mapAttrs
      (name: binds: bindsToList binds)
      keyBinds;
  };
}
