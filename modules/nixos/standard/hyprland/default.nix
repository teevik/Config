{
  inputs,
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  hyprlandPackage = perSystem.hyprland.hyprland;
  portalPackage = perSystem.hyprland.xdg-desktop-portal-hyprland;
  # TODO: use upstream
  nwgDisplays = pkgs.nwg-displays.overrideAttrs (_: {
    version = "0.4.3";
    src = pkgs.fetchFromGitHub {
      owner = "nwg-piotr";
      repo = "nwg-displays";
      tag = "v0.4.3";
      hash = "sha256-f7x6PTsND0eprhqvIdkZdHujcCbkJnqoXIKeE0O/YPE=";
    };
  });
  splitMonitorWorkspacesLua = pkgs.runCommand "split-monitor-workspaces-lua" { } ''
    mkdir -p $out/share/hyprland/split-monitor-workspaces
    cp ${inputs.split-monitor-workspaces}/lua/*.lua $out/share/hyprland/split-monitor-workspaces/
  '';

  # Lid handler: disable internal display when lid closes and an external
  # monitor is connected. Re-enable on lid open.
  lidHandler = pkgs.writeShellApplication {
    name = "hyprland-lid-handler";
    runtimeInputs = with pkgs; [
      hyprlandPackage
      jq
    ];
    text = ''
      INTERNAL="eDP-1"
      state="''${1:-}"

      # Auto-detect from /proc if no arg given (used on startup)
      if [ -z "$state" ]; then
        if grep -qs closed /proc/acpi/button/lid/*/state; then
          state="close"
        else
          state="open"
        fi
      fi

      case "$state" in
        close)
          external_count=$(hyprctl -j monitors | jq "[.[] | select(.name != \"$INTERNAL\")] | length")
          if [ "$external_count" -gt 0 ]; then
            hyprctl keyword monitor "$INTERNAL,disable"
          fi
          ;;
        open)
          # Re-source monitor config managed by nwg-displays to restore exact settings
          hyprctl reload
          ;;
      esac
    '';
  };

  enableDisplays = pkgs.writeShellApplication {
    name = "hyprland-enable-displays";
    runtimeInputs = [
      hyprlandPackage
      pkgs.jq
    ];
    text = ''
      hyprctl dispatch dpms on || true

      monitors="$(hyprctl -j monitors all | jq -r '.[]?.name // empty' || true)"

      if [ -z "$monitors" ]; then
        hyprctl keyword monitor ",preferred,auto,auto"
        exit 0
      fi

      printf '%s\n' "$monitors" | while IFS= read -r monitor; do
        hyprctl keyword monitor "$monitor,preferred,auto,auto"
      done
    '';
  };
in
{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = hyprlandPackage;
    portalPackage = portalPackage;
  };

  programs.uwsm.enable = true;

  environment.systemPackages = [
    nwgDisplays
    perSystem.hyprland-scratchpad.default
    splitMonitorWorkspacesLua
    lidHandler
    enableDisplays
  ];

  # buildEnv only links share/ subdirs listed in pathsToLink. The upstream
  # hyprland module adds /share/hypr (singular). split-monitor-workspaces
  # ships its lua under /share/hyprland (plural), so we must opt-in.
  environment.pathsToLink = [ "/share/hyprland" ];

  system.activationScripts.nwgDisplaysConfig.text = ''
    mkdir -p /home/teevik/.config/hypr
    [ -f /home/teevik/.config/hypr/monitors.lua ] || printf '%s\n' 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })' > /home/teevik/.config/hypr/monitors.lua
    [ -f /home/teevik/.config/hypr/workspaces.lua ] || touch /home/teevik/.config/hypr/workspaces.lua
    chown -R teevik:users /home/teevik/.config/hypr
  '';

  # HACK: Workaround for https://github.com/NixOS/nixpkgs/issues/485123
  # Launch Hyprland directly via UWSM with -F to bypass broken desktop file lookup
  environment.loginShellInit = ''
    if [ "$(tty)" == /dev/tty1 ] && uwsm check may-start; then
      uwsm start hyprland.desktop
    fi
  '';

  # Hypridle - screen dimming and DPMS
  systemd.user.services.hypridle = {
    description = "Hyprland idle daemon";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${./hypridle.conf}";
      Restart = "on-failure";
    };
  };

  # Swaybg - wallpaper daemon
  systemd.user.services.swaybg = {
    description = "Wayland wallpaper daemon";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.swaybg} -i ${./background.png} -m fill";
    };
  };
}
