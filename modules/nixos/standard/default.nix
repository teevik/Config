{
  config,
  ...
}:
{
  imports = [
    ./age
    ./apps
    ./cachix.nix
    ./docker.nix
    ./fonts.nix
    ./pipewire.nix
    ./polkit.nix
    ./shells.nix
    ./tailscale.nix
    ./hyprland
  ];

  home-manager.backupFileExtension = "backup";

  nix = {
    extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens-github.path}
    '';
  };

  # Boot
  boot = {
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "150%";

    loader = {
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
