{
  inputs,
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.x86_64-linux.hyprland;
  portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;

  # Lid handler: disable internal display when lid closes and an external
  # monitor is connected. Re-enable on lid open.
  lidHandler = pkgs.writeShellApplication {
    name = "hyprland-lid-handler";
    runtimeInputs = with pkgs; [
      hyprland
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
in
{
  imports = [ inputs.hyprland.nixosModules.default ];

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = hyprlandPackage;
    portalPackage = portalPackage;
    plugins = [
      perSystem.split-monitor-workspaces.split-monitor-workspaces
    ];
    extraConfig = builtins.readFile ./hyprland.conf;
  };

  programs.uwsm.enable = true;

  environment.systemPackages = [
    pkgs.nwg-displays
    perSystem.hyprland-scratchpad.default
    lidHandler
  ];

  # Ensure the config files exist for nwg-displays
  system.activationScripts.nwgDisplaysConfig.text = ''
    mkdir -p /home/teevik/.config/hypr
    [ -f /home/teevik/.config/hypr/monitors.conf ] || touch /home/teevik/.config/hypr/monitors.conf
    [ -f /home/teevik/.config/hypr/workspaces.conf ] || touch /home/teevik/.config/hypr/workspaces.conf
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
