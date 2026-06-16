{
  inputs,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  hyprlandPackage = perSystem.hyprland.hyprland;
  hyprlandModuleDir = ../../modules/nixos/standard/hyprland;
  glycinGtk4LibraryPath = "${pkgs.libglycin-gtk4}/lib";
  glycinGtk4TypelibPath = "${pkgs.libglycin-gtk4}/lib/girepository-1.0";

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

  lidHandler = pkgs.writeShellApplication {
    name = "hyprland-lid-handler";
    runtimeInputs = [
      hyprlandPackage
      pkgs.gnugrep
      pkgs.jq
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

  uwsmUserUnits = [
    "app-graphical.slice"
    "background-graphical.slice"
    "session-graphical.slice"
    "wayland-session-envelope@.target"
    "wayland-session-pre@.target"
    "wayland-session-shutdown.target"
    "wayland-session@.target"
    "wayland-session-xdg-autostart@.target"
    "wayland-session-bindpid@.service"
    "wayland-session-waitenv.service"
    "wayland-wm-app-daemon.service"
    "wayland-wm-env@.service"
    "wayland-wm@.service"
    "fumon.service"
  ];

  uwsmUserUnitEtc = lib.listToAttrs (
    map (name: {
      name = "systemd/user/${name}";
      value.source = "${pkgs.uwsm}/lib/systemd/user/${name}";
    }) uwsmUserUnits
  );

  marbleWithGlycinGtk4 = pkgs.writeShellApplication {
    name = "marble-with-glycin-gtk4";
    text = ''
      export GI_TYPELIB_PATH="${glycinGtk4TypelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      export LD_LIBRARY_PATH="${glycinGtk4LibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${perSystem.marble.default}/bin/marble "$@"
    '';
  };

  marbleService = pkgs.writeText "marble.service" ''
    [Unit]
    Description=Marble Shell
    PartOf=graphical-session.target
    After=graphical-session.target

    [Service]
    ExecStart=${marbleWithGlycinGtk4}/bin/marble-with-glycin-gtk4
    ExecReload=${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID
    Restart=on-failure
    KillMode=mixed

    [Install]
    WantedBy=graphical-session.target
  '';

  hypridleConfig = pkgs.writeText "hypridle.conf" ''
    listener {
        timeout = 300
        on-timeout = ${pkgs.brightnessctl}/bin/brightnessctl s 50%-
        on-resume = ${pkgs.brightnessctl}/bin/brightnessctl s 50%+
    }

    listener {
        timeout = 600
        on-timeout = ${hyprlandPackage}/bin/hyprctl dispatch dpms off
        on-resume = ${hyprlandPackage}/bin/hyprctl dispatch dpms on
    }
  '';

  hypridleService = pkgs.writeText "hypridle.service" ''
    [Unit]
    Description=Hyprland idle daemon
    PartOf=graphical-session.target
    After=graphical-session.target

    [Service]
    ExecStart=${pkgs.hypridle}/bin/hypridle -c ${hypridleConfig}
    Restart=on-failure

    [Install]
    WantedBy=graphical-session.target
  '';

  swaybgService = pkgs.writeText "swaybg.service" ''
    [Unit]
    Description=Wayland wallpaper daemon
    PartOf=graphical-session.target
    After=graphical-session.target

    [Service]
    Type=simple
    ExecStart=${lib.getExe pkgs.swaybg} -i ${hyprlandModuleDir}/background.png -m fill

    [Install]
    WantedBy=graphical-session.target
  '';

  graphicalSessionUserServices = {
    "hypridle.service" = hypridleService;
    "marble.service" = marbleService;
    "swaybg.service" = swaybgService;
  };

  graphicalSessionUserServiceEtc = lib.listToAttrs (
    lib.concatMap (name: [
      {
        name = "systemd/user/${name}";
        value.source = graphicalSessionUserServices.${name};
      }
      {
        name = "systemd/user/graphical-session.target.wants/${name}";
        value.source = graphicalSessionUserServices.${name};
      }
    ]) (lib.attrNames graphicalSessionUserServices)
  );
in
{
  imports = [
    inputs.nix-system-graphics.systemModules.default
    flake.modules.shared.packages
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;

  fonts.fontconfig.enable = true;

  environment = {
    etc = {
      "nix/nix.custom.conf".text = ''
        experimental-features = nix-command flakes ca-derivations dynamic-derivations parallel-eval
        auto-optimise-store = true
        trusted-users = root teemu.vikoeren
        max-substitution-jobs = 128
        http-connections = 128
        eval-cores = 0
        lazy-trees = true
        keep-derivations = true
        keep-outputs = true
        connect-timeout = 5
        fallback = true
        substituters = https://cache.nixos.org https://teevik.cachix.org https://hyprland.cachix.org https://install.determinate.systems
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= desktop-1:VvIgYHAClUfjQjKWeNaCiQTRm9Q3fO0Q3v08KLTp0yo= teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
      '';
    }
    // uwsmUserUnitEtc
    // graphicalSessionUserServiceEtc;

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      QT_STYLE_OVERRIDE = "adwaita-dark";
    };

    extraInit = ''
      export XDG_DATA_DIRS="/run/system-manager/sw/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share:/var/lib/snapd/desktop}"
      export GI_TYPELIB_PATH="${glycinGtk4TypelibPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      export LD_LIBRARY_PATH="${glycinGtk4LibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    '';

    pathsToLink = [
      "/bin"
      "/share/applications"
      "/share/fonts"
      "/share/glib-2.0/schemas"
      "/share/hypr"
      "/share/hyprland"
      "/share/icons"
      "/share/mime"
      "/share/nautilus-python/extensions"
      "/share/pixmaps"
      "/share/themes"
      "/share/thumbnailers"
      "/share/wayland-sessions"
    ];

    systemPackages = with pkgs; [
      perSystem.system-manager.default

      firefox
      hyprlandPackage
      uwsm
      brightnessctl
      hypridle
      libglycin-gtk4
      marbleWithGlycinGtk4
      nwgDisplays
      perSystem.hyprland-scratchpad.default
      splitMonitorWorkspacesLua
      lidHandler
      enableDisplays

      iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      nerd-fonts.ubuntu
      nerd-fonts.fira-code
      source-sans
    ];
  };
}
