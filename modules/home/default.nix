{ lib, options, config, inputs, ... }:
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.teevik.home = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Options to pass directly to home-manager.";
  };

  config = {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.teevik =
        lib.mkAliasDefinitions options.teevik.home;
    };
  };

  config.teevik.home = {
    home.stateVersion = config.system.stateVersion;

    systemd.user.startServices = "sd-switch";

    xdg = {
      enable = true;

      userDirs = {
        enable = true;
        createDirectories = true;

        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.users.users.teevik.home}/Pictures/Screenshots";
        };
      };
    };
  };
}
