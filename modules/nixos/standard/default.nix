{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./age # Keep for manual secret migration
    ./sops
    ./apps
    ./hyprland
    ./cachix.nix
    ./docker.nix
    ./fonts.nix
    ./pipewire.nix
    ./polkit.nix
    ./shells.nix
    ./tailscale.nix
  ];

  home-manager.backupFileExtension = "backup";

  nix = {
    extraOptions = ''
      !include ${config.sops.secrets.nix-access-tokens-github.path}
    '';
  };

  # Boot
  boot = {
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "150%";

    initrd.systemd.enable = true;

    # Silent boot
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];

    loader = {
      timeout = null;

      systemd-boot = {
        enable = true;
        configurationLimit = 50;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  services = {
    # TimeZone
    automatic-timezoned.enable = true;

    gnome = {
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      gnome-keyring.enable = true;
      gcr-ssh-agent.enable = false;
      gnome-online-accounts.enable = true;
      localsearch.enable = true;
      tinysparql.enable = true;
    };

    geoclue2 = {
      enable = true;
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
      submissionUrl = "https://api.beacondb.net/v2/geosubmit";

      enableNmea = false;

      # appConfig.geoshift = {
      #   isAllowed = true;
      #   isSystem = false;
      #   users = [ ];
      # };
    };
  };

  # users.users.teevik.extraGroups = [ "geoclue" ];
}
