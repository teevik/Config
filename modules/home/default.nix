{ pkgs, lib, options, config, inputs, ... }:
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.home = lib.mkOption {
    type = lib.types.attrs;
    default = { };
    description = "Options to pass directly to home-manager.";
  };

  config = {
    home = {
      home.packages = with pkgs; [ comma ];

      home.stateVersion = config.system.stateVersion;
      # home.file = lib.mkAliasDefinitions options.pagman.home.file;
      # xdg.enable = true;
      # xdg.configFile = lib.mkAliasDefinitions options.pagman.home.configFile;
      
      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";      

      xdg = {
        enable = true;

        userDirs = {
          enable = true;
          createDirectories = true;
        };
      };

      programs = {
        git = {
          enable = true;
          userEmail = "teemu.vikoren@gmail.com";
          userName = "teevik";
        };

        # alacritty = {
        #   enable = true;
        # };
      };
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.teevik =
        lib.mkAliasDefinitions options.home;
    };
  };
} 