local home = os.getenv("HOME") or "/home/teevik"
local config_dir = (os.getenv("XDG_CONFIG_HOME") or home .. "/.config") .. "/hypr"

package.path = "/run/current-system/sw/share/hyprland/split-monitor-workspaces/?.lua;" .. package.path
local smw = require("split-monitor-workspaces")

dofile(config_dir .. "/monitors.lua")
dofile(config_dir .. "/workspaces.lua")

hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -- 1password --silent")
  hl.exec_cmd("uwsm app -- firefox http://glance/")
  hl.exec_cmd("hyprland-lid-handler")
end)

hl.config({
  cursor = {
    inactive_timeout = 10,
  },

  misc = {
    disable_hyprland_logo = true,
    force_default_wallpaper = 1,
    focus_on_activate = true,
    animate_manual_resizes = true,
    close_special_on_empty = false,
    on_focus_under_fullscreen = 2,
    middle_click_paste = false,
  },

  input = {
    kb_layout = "us,no",
    kb_options = "grp:alt_shift_toggle,caps:escape",
    follow_mouse = 1,
    natural_scroll = false,
    sensitivity = 0,

    touchpad = {
      natural_scroll = true,
      disable_while_typing = false,
    },
  },

  xwayland = {
    force_zero_scaling = true,
  },

  general = {
    layout = "dwindle",
    gaps_in = 8,
    gaps_out = 12,
    border_size = 2,

    col = {
      active_border = "rgb(eba0ac)",
      inactive_border = "rgba(eba0ac30)",
    },
  },

  dwindle = {
    preserve_split = true,
    smart_split = true,
  },

  master = {
    orientation = "center",
    slave_count_for_center_master = 0,
  },

  decoration = {
    rounding = 4,
    dim_inactive = true,
    dim_strength = 0,
    dim_special = 0.5,

    shadow = {
      enabled = true,
      offset = { 0, 5 },
      range = 50,
      render_power = 3,
      color = "rgba(1a1a1a1a)",
    },

    blur = {
      enabled = true,
      size = 10,
      passes = 3,
      new_optimizations = true,
      xray = true,
      special = true,
    },
  },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.curve("default", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

smw.setup({
  workspace_count = 10,
  keep_focused = true,
  enable_notifications = false,
  enable_persistent_workspaces = true,
})

local float_classes =
"^(feh|yad|nm-connection-editor|pavucontrolk|xfce-polkit|kvantummanager|qt5ct|VirtualBox Manager|qemu|Qemu-system-x86_64|1Password|org.gnome.Calculator|org.gnome.Nautilus|pavucontrol|nm-connection-editor|blueberry.py|org.gnome.Settings|org.gnome.design.Palette|Color Picker|xdg-desktop-portal|xdg-desktop-portal-gnome|de.haeckerfelix.Fragments)$"

hl.window_rule({ name = "float-common-dialogs", match = { class = float_classes }, float = true })
hl.window_rule({ name = "center-feh", match = { class = "^(feh)$" }, center = true })
hl.window_rule({
  name = "suppress-libreoffice-maximize",
  match = { class = "^(libreoffice.*)$" },
  suppress_event = "maximize",
})
hl.window_rule({ name = "steam-stay-focused", match = { class = "^(steam)$" }, stay_focused = true })
hl.window_rule({ name = "steam-min-size", match = { class = "^(steam)$" }, min_size = { 1, 1 } })

hl.layer_rule({ name = "blur-bar", match = { namespace = "bar" }, blur = true })
hl.layer_rule({ name = "blur-osd", match = { namespace = "osd" }, blur = true })
hl.layer_rule({ name = "blur-notifications", match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ name = "blur-launcher", match = { namespace = "launcher" }, blur = true })

local function exec(command)
  return hl.dsp.exec_cmd(command)
end

hl.bind("SUPER + SHIFT + Return", exec("uwsm app -- kitty"))
hl.bind("SUPER + Return", exec("hyprland-scratchpad toggle-exec --name terminal --exec 'uwsm app -- kitty'"))

hl.bind("SUPER + D", exec("uwsm app -- tofi-drun --drun-launch=true"))
hl.bind("SUPER + W", exec("uwsm app -- firefox"))
hl.bind("SUPER + F", exec("uwsm app -- nautilus"))
hl.bind("SUPER + E", exec("uwsm app -- zeditor"))
hl.bind("SUPER + Backspace", exec("hyprland-scratchpad toggle-exec --name discord --exec 'uwsm app -- vesktop'"))
hl.bind("SUPER + M", exec("hyprland-scratchpad toggle-exec --name spotify --exec 'uwsm app -- spotify'"))
hl.bind(
  "SUPER + S",
  exec(
    "hyprland-scratchpad toggle-exec --name settings --exec 'uwsm app -- env XDG_CURRENT_DESKTOP=gnome gnome-control-center'"
  )
)

hl.bind("Print", exec("XDG_SCREENSHOTS_DIR=" .. home .. "/Pictures/Screenshots grimblast --notify copysave output"))
hl.bind(
  "CTRL + Print",
  exec("XDG_SCREENSHOTS_DIR=" .. home .. "/Pictures/Screenshots grimblast --notify copysave area")
)
hl.bind(
  "SUPER + SHIFT + S",
  exec("XDG_SCREENSHOTS_DIR=" .. home .. "/Pictures/Screenshots grimblast --notify copysave area")
)

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())
hl.bind("SUPER + A", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + Q", exec("poweroff"))

hl.bind("SUPER + L", exec("hyprland-lock"))
hl.bind("SUPER + SHIFT + L", exec("hyprctl keyword general:layout master"))

hl.bind("XF86MonBrightnessUp", exec("brightnessctl s --min-value=10 --exponent=2 7%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl s --min-value=10 --exponent=2 7%-"), { repeating = true })
hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"), { repeating = true })
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioNext", exec("playerctl next"))
hl.bind("XF86AudioPrev", exec("playerctl previous"))
hl.bind("XF86AudioPlay", exec("playerctl play-pause"))
hl.bind("XF86AudioStop", exec("playerctl stop"))

hl.bind("SUPER + mouse_down", smw.cycle_workspaces("prev"))
hl.bind("SUPER + mouse_up", smw.cycle_workspaces("next"))
hl.bind("mouse_right", smw.cycle_workspaces("next"))
hl.bind("mouse_left", smw.cycle_workspaces("prev"))

hl.bind("SUPER + left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "d" }))

hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

for i = 1, smw.get_amount_of_workspaces() do
  local workspace = tostring(i)
  local key = workspace
  if key == "10" then
    key = "0"
  end

  hl.bind("SUPER + " .. key, smw.workspace(workspace))
  hl.bind("SUPER + SHIFT + " .. key, smw.move_to_workspace_silent(workspace))
end
