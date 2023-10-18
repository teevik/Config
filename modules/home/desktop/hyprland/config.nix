{ config, enableVrr, enableMasterLayout, enableHidpi, scaling, monitor }:
let
  theme = config.teevik.theme;
  cursorName = config.gtk.cursorTheme.name;
in
''
  ${if monitor.enable then ''
    monitor=,${monitor.resolution}@${toString monitor.refreshRate},auto,${toString scaling}${if monitor.bitDepth != null then ",bitdepth,10" else ""}
  '' else ''
    monitor=,preferred,auto,${toString scaling}
  ''}

  env = XCURSOR_SIZE,${toString (24*scaling)}

  ${
    if enableHidpi
    then ''
      xwayland {
        force_zero_scaling = true
      }

      exec-once = xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE ${toString (16 * scaling)}c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE ${toString scaling}
      exec-once = hyprctl setcursor ${cursorName} ${toString (12 * scaling)}

      env = GDK_SCALE,${toString scaling}
    ''
    else ""
  }

  misc {
      vrr = ${if enableVrr then "1" else "0" }

      enable_swallow = true
      swallow_regex = ^(org.wezfurlong.wezterm)$
      focus_on_activate = true
      animate_manual_resizes = true
      close_special_on_empty = false
  }

  input {
      kb_layout=us,no
      kb_options = grp:alt_shift_toggle
      kb_variant =
      kb_model =
      kb_rules =

      follow_mouse = 1
      natural_scroll=false

      touchpad {
          natural_scroll = true
          disable_while_typing = false
      }

      sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
  }

  # Thinkpad trackpad
  device:tpps/2-elan-trackpoint {
      # sensitivity = -0.35
  }

  device:logitech-usb-receiver {
      sensitivity = 0.75
  }

  gestures {
      workspace_swipe = true
      #workspace_swipe_use_r = true
  }

  general {
      layout = ${
    if enableMasterLayout
    then "master"
    else "dwindle"
    }

      gaps_in=8
      gaps_out=12
      border_size = 2
      col.active_border=rgb(${theme.borderColor})
      col.inactive_border=rgba(${theme.borderColor}30)
  }

  decoration {
      rounding=4

      dim_inactive = true
      dim_strength = 0
      dim_special	= 0.5

      drop_shadow = true
      shadow_offset = 0 5
      shadow_range = 50
      shadow_render_power = 3
      col.shadow = rgba(1a1a1a1a)

      blur {
        enabled = true
        size = 10
        passes = 3
        new_optimizations = true
        xray = true
        special = true
      }
  }

  animations {
      enabled = true
      bezier = myBezier, 0.05, 0.9, 0.1, 1.05

      animation = windows, 1, 7, myBezier
      animation = windowsOut, 1, 7, default, popin 80%
      animation = border, 1, 10, default
      animation = borderangle, 1, 8, default
      animation = fade, 1, 7, default
      animation = workspaces, 1, 6, default
  }

  dwindle {
      pseudotile = false
      preserve_split = true
  }

  master {
      orientation = center
      always_center_master = true
      new_is_master = false
  }

  windowrule = float, feh|MPlayer

  windowrule = float, yad|nm-connection-editor|pavucontrolk
  windowrule = float, xfce-polkit|kvantummanager|qt5ct
  windowrule = float, VirtualBox Manager|qemu|Qemu-system-x86_64

  # windowrulev2 = workspace special:spotify, class:^(Spotify)$

  # $terminal = wezterm start --always-new-process
  $terminal = kitty
  # $menu = tofi-drun --drun-launch=true
  $menu = anyrun
  $browser = firefox
  $discord = webcord
  $spotify = spotify
  $files = nautilus
  $editor = code

  # -- Apps --
  bind = SUPER_SHIFT, Return, exec, $terminal
  bind = SUPER, Return, exec, hyprland-scratchpad toggle-exec --name terminal --exec '$terminal'

  bind = SUPER, D, exec, $menu
  bind = SUPER, W, exec, $browser
  bind = SUPER, F ,exec, $files
  bind = SUPER, E ,exec, $editor
  bind = SUPER, Backspace ,exec, hyprland-scratchpad toggle-exec --name discord --exec '$discord'
  bind = SUPER, M ,exec, hyprland-scratchpad toggle-exec --name spotify --exec '$spotify'

  # -- Screenshot --
  $XDG_SCREENSHOTS_DIR = /home/teevik/Pictures/Screenshots
  bind = , Print ,exec, XDG_SCREENSHOTS_DIR=$XDG_SCREENSHOTS_DIR shotman --copy --capture output
  bind = CTRL, Print, exec, XDG_SCREENSHOTS_DIR=$XDG_SCREENSHOTS_DIR shotman --copy --capture region

  # -- Hyprland --
  bind = SUPER, Q, killactive,
  bind = CTRLALT, Delete, exit,
  bind = SUPER, A, fullscreen,
  bind = SUPER, Space, togglefloating,
  bind = SUPER_SHIFT, Q, exec, poweroff

  # -- Function keys --
  binde=,XF86MonBrightnessUp,exec, light -A 10
  binde=,XF86MonBrightnessDown,exec, light -U 10
  binde=,XF86AudioRaiseVolume,exec, pulsemixer --change-volume +10
  binde=,XF86AudioLowerVolume,exec, pulsemixer --change-volume -10
  bind=,XF86AudioMute,exec, pulsemixer --toggle-mute
  bind=,XF86AudioNext,exec,playerctl next
  bind=,XF86AudioPrev,exec,playerctl previous
  bind=,XF86AudioPlay,exec,playerctl play-pause
  bind=,XF86AudioStop,exec,playerctl stop

  # Scroll through existing workspaces with SUPER + scroll
  bind = SUPER, mouse_down, workspace, e+1
  bind = SUPER, mouse_up, workspace, e-1

  bind = , mouse_right, workspace, e+1
  bind = , mouse_left, workspace, e-1


  # Focus
  bind=SUPER,left,movefocus,l
  bind=SUPER,right,movefocus,r
  bind=SUPER,up,movefocus,u
  bind=SUPER,down,movefocus,d

  # Move
  bind=SUPERSHIFT,left,movewindow,l
  bind=SUPERSHIFT,right,movewindow,r
  bind=SUPERSHIFT,up,movewindow,u
  bind=SUPERSHIFT,down,movewindow,d
  bindm=SUPER,mouse:272,movewindow
  bindm=SUPERSHIFT,mouse:272,resizewindow

  # Resize
  bind=SUPERCTRL,left,resizeactive,-20 0
  bind=SUPERCTRL,right,resizeactive,20 0
  bind=SUPERCTRL,up,resizeactive,0 -20
  bind=SUPERCTRL,down,resizeactive,0 20

  # Workspaces
  bind=SUPER,1,workspace,1
  bind=SUPER,2,workspace,2
  bind=SUPER,3,workspace,3
  bind=SUPER,4,workspace,4
  bind=SUPER,5,workspace,5
  bind=SUPER,6,workspace,6
  bind=SUPER,7,workspace,7
  bind=SUPER,8,workspace,8
  bind=SUPER,9,workspace,9
  bind=SUPER,0,workspace,10

  # Send to Workspaces
  bind=SUPER_SHIFT,1,movetoworkspace,1
  bind=SUPER_SHIFT,2,movetoworkspace,2
  bind=SUPER_SHIFT,3,movetoworkspace,3
  bind=SUPER_SHIFT,4,movetoworkspace,4
  bind=SUPER_SHIFT,5,movetoworkspace,5
  bind=SUPER_SHIFT,6,movetoworkspace,6
  bind=SUPER_SHIFT,7,movetoworkspace,7
  bind=SUPER_SHIFT,8,movetoworkspace,8
  bind=SUPER_SHIFT,9,movetoworkspace,9
  bind=SUPER_SHIFT,0,movetoworkspace,10
''
