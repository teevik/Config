{
  inputs,
  perSystem,
  pkgs,
  ...
}:
let
  hyprlandPackage = inputs.hyprland.packages.x86_64-linux.hyprland;
  portalPackage = inputs.hyprland.packages.x86_64-linux.xdg-desktop-portal-hyprland;
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
      uwsm start -F -D Hyprland -- /run/current-system/sw/bin/hyprland
    fi
  '';
}
