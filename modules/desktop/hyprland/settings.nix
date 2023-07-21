{ config, lib, enableVrr, enableMasterLayout, enableHidpi }:
let
  terminal = "wezterm";
  menu = "tofi-drun --drun-launch=true";
  browser = "google-chrome-stable";
  discord = "webcord";
  spotify = "spotify";
  files = "nautilus";
  editor = "code";
  XDG_SCREENSHOTS_DIR = "${config.users.users.teevik.home}/Pictures/Screenshots";
in
{
  monitor = [
    "desc:Samsung Electric Company Odyssey G8 H1AK500000,3440x1440@175,auto,1,bitdepth,10"
    "monitor=,preferred,auto,${if enableHidpi then "1" else "2"}"
  ];

  exec-once = lib.mkIf enableHidpi "xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2";

  env = if enableHidpi then [ "GDK_SCALE,2" "XCURSOR_SIZE,48" ] else [ "XCURSOR_SIZE,24" ];

  misc = {
    vrr = enableVrr;
    focus_on_activate = true;
    animate_manual_resizes = true;

    # enable_swallow = true;
    # swallow_regex = "^(org.wezfurlong.wezterm)$";
  };

  input = {
    kb_layout = "us,no";
    kb_options = "grp:alt_shift_toggle";

    follow_mouse = true;
    natural_scroll = false;

    touchpad = {
      natural_scroll = true;
      disable_while_typing = false;
    };

    sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
  };

  "device:logitech-usb-receiver" = {
    sensitivity = 0.75;
  };

  gestures = {
    workspace_swipe = true;
    # workspace_swipe_use_r = true;
  };

  general = {
    layout = if enableMasterLayout then "master" else "dwindle";

    gaps_in = 8;
    gaps_out = 12;
    border_size = 2;
    "col.active_border" = "0xFFc6a0f6";
    "col.inactive_border" = "0x30c6a0f6";
  };

  decoration = {
    rounding = 4;

    blur = true;
    blur_size = 8;
    blur_passes = 4;
    blur_new_optimizations = true;
    blur_xray = true;

    dim_inactive = true;
    dim_strength = 0;
    dim_special = 0.5;

    drop_shadow = true;
    shadow_range = 4;
    shadow_render_power = 3;
    "col.shadow" = "rgba(1a1a1aee)";
  };

  dwindle = {
    pseudotile = false;
    preserve_split = true;
  };

  master = {
    orientation = "center";
    always_center_master = true;
    new_is_master = false;
  };

  windowrule = [
    "float, feh|MPlayer"
    "float, yad|nm-connection-editor|pavucontrolk"
    "float, xfce-polkit|kvantummanager|qt5ct"
    "float, VirtualBox Manager|qemu|Qemu-system-x86_64"
  ];

  bind = [
    # Apps
    "SUPER_SHIFT, Return, exec, ${terminal}"
    "SUPER, Return, exec, hyprland-scratchpad toggle-exec --name terminal --exec 'alacritty'"
    "SUPER, D, exec, ${menu}"
    "SUPER, W, exec, ${browser}"
    "SUPER, F ,exec, ${files}"
    "SUPER, E ,exec, ${editor}"
    "SUPER, Backspace ,exec, hyprland-scratchpad toggle-exec --name discord --exec '${discord}'"
    "SUPER, M ,exec, hyprland-scratchpad toggle-exec --name spotify --exec '${spotify}'"

    # Screenshots
    ", Print ,exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} shotman --copy --capture output"
    "CTRL, Print, exec, XDG_SCREENSHOTS_DIR=${XDG_SCREENSHOTS_DIR} shotman --copy --capture region"

    # Hyprland
    "SUPER, Q, killactive,"
    "CTRLALT, Delete, exit,"
    "SUPER, A, fullscreen,"
    "SUPER, Space, togglefloating,"
    "SUPER_SHIFT, Q, exec, poweroff"

    # Function keys
    ",XF86AudioMute,exec, pulsemixer --toggle-mute"
    ",XF86AudioNext,exec,playerctl next"
    ",XF86AudioPrev,exec,playerctl previous"
    ",XF86AudioPlay,exec,playerctl play-pause"
    ",XF86AudioStop,exec,playerctl stop"

    # Scroll through workspaces with SUPER + scroll
    "SUPER, mouse_down, workspace, r+1"
    "SUPER, mouse_up, workspace, r-1"
    ", mouse_right, workspace, r+1"
    ", mouse_left, workspace, r-1"

    # Focus
    "SUPER,left,movefocus,l"
    "SUPER,right,movefocus,r"
    "SUPER,up,movefocus,u"
    "SUPER,down,movefocus,d"

    # Move
    "SUPERSHIFT,left,movewindow,l"
    "SUPERSHIFT,right,movewindow,r"
    "SUPERSHIFT,up,movewindow,u"
    "SUPERSHIFT,down,movewindow,d"

    # Resize
    "SUPERCTRL,left,resizeactive,-20 0"
    "SUPERCTRL,right,resizeactive,20 0"
    "SUPERCTRL,up,resizeactive,0 -20"
    "SUPERCTRL,down,resizeactive,0 20"

    # Workspaces
    "SUPER,1,workspace,1"
    "SUPER,2,workspace,2"
    "SUPER,3,workspace,3"
    "SUPER,4,workspace,4"
    "SUPER,5,workspace,5"
    "SUPER,6,workspace,6"
    "SUPER,7,workspace,7"
    "SUPER,8,workspace,8"
    "SUPER,9,workspace,9"
    "SUPER,0,workspace,10"

    # Send to Workspaces
    "SUPER_SHIFT,1,movetoworkspace,1"
    "SUPER_SHIFT,2,movetoworkspace,2"
    "SUPER_SHIFT,3,movetoworkspace,3"
    "SUPER_SHIFT,4,movetoworkspace,4"
    "SUPER_SHIFT,5,movetoworkspace,5"
    "SUPER_SHIFT,6,movetoworkspace,6"
    "SUPER_SHIFT,7,movetoworkspace,7"
    "SUPER_SHIFT,8,movetoworkspace,8"
    "SUPER_SHIFT,9,movetoworkspace,9"
    "SUPER_SHIFT,0,movetoworkspace,10"
  ];

  binde = [
    # Function keys
    ",XF86MonBrightnessUp,exec, light -A 10"
    ",XF86MonBrightnessDown,exec, light -U 10"
    ",XF86AudioRaiseVolume,exec, pulsemixer --change-volume +10"
    ",XF86AudioLowerVolume,exec, pulsemixer --change-volume -10"
  ];

  bindm = [
    # Move
    "SUPER,mouse:272,movewindow"
    "SUPERSHIFT,mouse:272,resizewindow"
  ];
}
