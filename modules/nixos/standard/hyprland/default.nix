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
  splitMonitorWorkspacesLua = pkgs.runCommand "split-monitor-workspaces-lua" { } ''
    mkdir -p $out/share/hyprland/split-monitor-workspaces
    cp ${inputs.split-monitor-workspaces}/lua/*.lua $out/share/hyprland/split-monitor-workspaces/
  '';
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
    pkgs.nwg-displays
    perSystem.hyprland-scratchpad.default
    splitMonitorWorkspacesLua
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
