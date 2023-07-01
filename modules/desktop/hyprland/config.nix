{ enableVrr, enableMasterLayout, enableHidpi }:
''
  monitor=desc:Samsung Electric Company Odyssey G8 H1AK500000,3440x1440@175,auto,1,bitdepth,10

  ${if enableHidpi then ''
    monitor=,preferred,auto,2

    exec-once = xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2

    env = GDK_SCALE,2
    env = XCURSOR_SIZE,48
  '' else ''
    monitor=,preferred,auto,1

    env = XCURSOR_SIZE,24
  ''}

  misc {
      vrr = ${if enableVrr then "1" else "0"}

      enable_swallow = true
      swallow_regex = ^(Alacritty)$
      focus_on_activate = true

    #   no_direct_scanout = false
    #   render_ahead_of_time = true
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
  }

  general {
      layout = ${if enableMasterLayout then "master" else "dwindle"}

      gaps_in=8
      gaps_out=12
      border_size = 2
      col.active_border=0xFFc6a0f6
      col.inactive_border=0x30c6a0f6
  }

  decoration {
      rounding=4

      blur = true
      blur_size = 8
      blur_passes = 4
      blur_new_optimizations = true
      blur_xray = true

      dim_inactive = true
      dim_strength = 0
      dim_special	= 0.5

      # drop_shadow = true
      # shadow_range = 4
      # shadow_render_power = 3
      # col.shadow = rgba(1a1a1aee)
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

  # windowrulev2 = tile, class:^(Spotify)$
  # windowrulev2 = workspace special:spotify, class:^(Spotify)$

  $terminal = alacritty
  $menu = tofi-drun --drun-launch=true
  $browser = google-chrome-stable
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
  bind = , Print ,exec, shotman --copy --capture output
  bind = CTRL, Print, exec, shotman --copy --capture region

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
