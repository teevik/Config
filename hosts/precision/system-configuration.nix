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
  hostPamModuleDir = "/usr/lib/x86_64-linux-gnu/security";

  nixElectronAppArmorProfile = pkgs.writeText "nix-electron-apparmor" ''
    abi <abi/4.0>,
    include <tunables/global>

    profile nix-electron /nix/store/*-electron-unwrapped-*/libexec/electron/electron flags=(default_allow) {
      userns,

      include if exists <local/nix-electron>
    }
  '';

  unloadNixElectronAppArmorProfile = pkgs.writeShellScript "unload-nix-electron-apparmor" ''
    if [ -x /usr/sbin/apparmor_parser ] && [ -e /sys/module/apparmor/parameters/enabled ]; then
      /usr/sbin/apparmor_parser --remove ${nixElectronAppArmorProfile} || true
    fi
  '';

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

  lockScreen = pkgs.writeShellApplication {
    name = "hyprland-lock";
    runtimeInputs = [
      pkgs.hyprlock
      pkgs.procps
    ];
    text = ''
      export LD_LIBRARY_PATH="${pkgs.libxcrypt-legacy}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      pidof hyprlock >/dev/null || exec hyprlock
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
    general {
        lock_cmd = ${lockScreen}/bin/hyprland-lock
        before_sleep_cmd = ${pkgs.systemd}/bin/loginctl lock-session
        after_sleep_cmd = ${hyprlandPackage}/bin/hyprctl dispatch dpms on
    }

    listener {
        timeout = 300
        on-timeout = ${pkgs.brightnessctl}/bin/brightnessctl s 50%-
        on-resume = ${pkgs.brightnessctl}/bin/brightnessctl s 50%+
    }

    listener {
        timeout = 600
        on-timeout = ${pkgs.systemd}/bin/loginctl lock-session
    }

    listener {
        timeout = 620
        on-timeout = ${hyprlandPackage}/bin/hyprctl dispatch dpms off
        on-resume = ${hyprlandPackage}/bin/hyprctl dispatch dpms on
    }
  '';

  hyprlockConfig = pkgs.writeText "hyprlock.conf" ''
    general {
        hide_cursor = true
    }

    background {
        monitor =
        path = ${hyprlandModuleDir}/background.png
        blur_passes = 3
        blur_size = 8
    }

    label {
        monitor =
        text = cmd[update:1000] ${pkgs.coreutils}/bin/date +"%H:%M"
        color = rgb(cdd6f4)
        font_size = 64
        font_family = Iosevka
        position = 0, 90
        halign = center
        valign = center
    }

    input-field {
        monitor =
        size = 320, 64
        outline_thickness = 2
        dots_size = 0.25
        dots_spacing = 0.2
        dots_center = true
        outer_color = rgb(eba0ac)
        inner_color = rgba(1e1e2eee)
        font_color = rgb(cdd6f4)
        check_color = rgb(f9e2af)
        fail_color = rgb(f38ba8)
        fade_on_empty = false
        placeholder_text = <i>Enter password</i>
        fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
        position = 0, -70
        halign = center
        valign = center
    }
  '';

  hypridleService = pkgs.writeText "hypridle.service" ''
    [Unit]
    Description=Hyprland idle daemon
    PartOf=graphical-session.target
    After=graphical-session.target

    [Service]
    ExecStart=${pkgs.hypridle}/bin/hypridle
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
    inputs.sops-nix.nixosModules.sops
    flake.modules.shared.packages
    (inputs.nixpkgs + "/nixos/modules/security/chromium-suid-sandbox.nix")
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;

  security.chromiumSuidSandbox.enable = true;

  fonts.fontconfig.enable = true;

  sops = {
    defaultSopsFile = ../../modules/nixos/standard/sops/secrets.yaml;
    age = {
      generateKey = false;
      keyFile = "/home/teemu.vikoeren/.config/sops/age/keys.txt";
    };

    secrets =
      lib.genAttrs
        [
          "mercury-ai-token"
          "excalidraw-token"
          "gemini-api-key"
          "brave-api-key"
        ]
        (_: {
          owner = "teemu.vikoeren";
          group = "root";
          mode = "0400";
        });
  };

  systemd.services.nix-electron-apparmor = {
    enable = true;
    description = "Load AppArmor profile for Nix Electron apps";
    after = [ "apparmor.service" ];
    wantedBy = [ "system-manager.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = unloadNixElectronAppArmorProfile;
    };
    script = ''
      if [ ! -x /usr/sbin/apparmor_parser ] || [ ! -e /sys/module/apparmor/parameters/enabled ]; then
        echo "AppArmor is not available, skipping Nix Electron profile"
        exit 0
      fi

      /usr/sbin/apparmor_parser --replace ${nixElectronAppArmorProfile}
    '';
  };

  environment = {
    etc = {
      "nix/nix.custom.conf".text = ''
        experimental-features = nix-command flakes ca-derivations dynamic-derivations
        auto-optimise-store = true
        trusted-users = root teemu.vikoeren
        max-substitution-jobs = 128
        http-connections = 128
        keep-derivations = true
        keep-outputs = true
        connect-timeout = 5
        fallback = true
        substituters = https://cache.nixos.org https://teevik.cachix.org https://hyprland.cachix.org https://install.determinate.systems
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= desktop-1:VvIgYHAClUfjQjKWeNaCiQTRm9Q3fO0Q3v08KLTp0yo= teevik.cachix.org-1:lh2jXPvLIaTNsL8e8gvrI2abYe83tKhV0PmxQOGlitQ= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM=
      '';

      "apparmor.d/nix-electron" = {
        source = nixElectronAppArmorProfile;
        mode = "0644";
      };

      "pam.d/hyprlock" = {
        text = ''
          auth required ${hostPamModuleDir}/pam_unix.so
          account required ${hostPamModuleDir}/pam_permit.so
        '';
        mode = "0644";
      };

      "xdg/hypr/hyprlock.conf" = {
        source = hyprlockConfig;
        mode = "0644";
      };

      "xdg/hypr/hypridle.conf" = {
        source = hypridleConfig;
        mode = "0644";
      };
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
      age
      sops

      firefox
      hyprlandPackage
      uwsm
      brightnessctl
      hypridle
      hyprlock
      lockScreen
      libglycin-gtk4
      marbleWithGlycinGtk4
      nwgDisplays
      perSystem.hyprland-scratchpad.default
      splitMonitorWorkspacesLua
      slack

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
