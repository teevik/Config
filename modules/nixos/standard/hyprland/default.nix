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
  mkHyprlockConfig =
    pamModule:
    pkgs.writeText "hyprlock-${pamModule}.conf" (
      lib.replaceStrings
        [
          "@date@"
          "@pam-module@"
          "@wallpaper@"
        ]
        [
          "${pkgs.coreutils}/bin/date"
          pamModule
          "${./background.png}"
        ]
        (builtins.readFile ./hyprlock.conf)
    );
  hyprlockConfig = mkHyprlockConfig "hyprlock";
  hyprlockManualConfig = mkHyprlockConfig "hyprlock-manual";
  mkLockScreen =
    {
      name,
      configFile,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.procps ];
      text = ''
        pidof hyprlock >/dev/null || exec ${lib.getExe pkgs.hyprlock} --config ${configFile}
      '';
    };
  lockScreen = mkLockScreen {
    name = "hyprland-lock";
    configFile = hyprlockManualConfig;
  };
  idleLockScreen = mkLockScreen {
    name = "hyprland-idle-lock";
    configFile = hyprlockConfig;
  };
  hypridleConfig = pkgs.writeText "hypridle.conf" (
    lib.replaceStrings
      [
        "@brightnessctl@"
        "@hyprctl@"
        "@lock-screen@"
        "@loginctl@"
      ]
      [
        "${lib.getExe pkgs.brightnessctl}"
        "${lib.getExe' hyprlandPackage "hyprctl"}"
        "${lib.getExe idleLockScreen}"
        "${pkgs.systemd}/bin/loginctl"
      ]
      (builtins.readFile ./hypridle.conf)
  );
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
    inherit portalPackage;
  };

  programs.uwsm.enable = true;

  environment = {
    systemPackages = [
      pkgs.nwg-displays
      pkgs.hyprlock
      lockScreen
      perSystem.hyprland-scratchpad.default
      splitMonitorWorkspacesLua
    ];

    # buildEnv only links share/ subdirs listed in pathsToLink. The upstream
    # hyprland module adds /share/hypr (singular). split-monitor-workspaces
    # ships its lua under /share/hyprland (plural), so we must opt-in.
    pathsToLink = [ "/share/hyprland" ];

    # HACK: Workaround for https://github.com/NixOS/nixpkgs/issues/485123
    # Launch Hyprland directly via UWSM with -F to bypass broken desktop file lookup
    loginShellInit = ''
      if [ "$(tty)" == /dev/tty1 ] && uwsm check may-start; then
        uwsm start hyprland.desktop
      fi
    '';
  };

  # Hyprlock uses this PAM service for password authentication. Individual
  # hosts can add another PAM method (the Zenbook adds Howdy) without changing
  # the lock screen itself.
  security.pam.services = {
    hyprlock = { };
    hyprlock-manual = { };
  };

  system.activationScripts.nwgDisplaysConfig.text = ''
    mkdir -p /home/teevik/.config/hypr
    [ -f /home/teevik/.config/hypr/monitors.lua ] || printf '%s\n' 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })' > /home/teevik/.config/hypr/monitors.lua
    [ -f /home/teevik/.config/hypr/workspaces.lua ] || touch /home/teevik/.config/hypr/workspaces.lua
    chown -R teevik:users /home/teevik/.config/hypr
  '';

  systemd.user.services = {
    # Hypridle - screen dimming, locking, and DPMS
    hypridle = {
      description = "Hyprland idle daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.hypridle} -c ${hypridleConfig}";
        Restart = "on-failure";
      };
    };

    # Cliphist - clipboard history for text and images
    cliphist = {
      description = "Clipboard history daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} -max-dedupe-search 10 -max-items 500 store";
        Restart = "on-failure";
      };
    };

    cliphist-images = {
      description = "Clipboard image history daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${lib.getExe pkgs.cliphist} -max-dedupe-search 10 -max-items 500 store";
        Restart = "on-failure";
      };
    };

    # Swaybg - wallpaper daemon
    swaybg = {
      description = "Wayland wallpaper daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.swaybg} -i ${./background.png} -m fill";
      };
    };
  };
}
