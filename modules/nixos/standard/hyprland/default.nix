{
  inputs,
  perSystem,
  pkgs,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.x86_64-linux.hyprland;
  portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;

  # HACK: Workaround for https://github.com/NixOS/nixpkgs/issues/485123
  # UWSM can't find wayland-sessions when display manager is disabled
  hyprlandSession = pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
    [Desktop Entry]
    Name=Hyprland
    Comment=An intelligent dynamic tiling Wayland compositor
    Exec=/run/current-system/sw/bin/start-hyprland
    Type=Application
    DesktopNames=Hyprland
  '';
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

  # Workaround: Add wayland-sessions to XDG_DATA_DIRS
  environment.systemPackages = [
    hyprlandSession
    pkgs.nwg-displays
    perSystem.hyprland-scratchpad.default
  ];

  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Ensure the config files exist for nwg-displays
  system.activationScripts.nwgDisplaysConfig.text = ''
    mkdir -p /home/teevik/.config/hypr
    [ -f /home/teevik/.config/hypr/monitors.conf ] || touch /home/teevik/.config/hypr/monitors.conf
    [ -f /home/teevik/.config/hypr/workspaces.conf ] || touch /home/teevik/.config/hypr/workspaces.conf
    chown -R teevik:users /home/teevik/.config/hypr
  '';

  # Auto-start Hyprland via UWSM from TTY1
  environment.loginShellInit = ''
    if [ "$(tty)" == /dev/tty1 ] && uwsm check may-start; then
      uwsm start hyprland
    fi
  '';
}
