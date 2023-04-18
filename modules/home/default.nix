{ lib, options, config, inputs, ... }:
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.pagman.home = with lib.types; {
    file = lib.mkOption {
      type = attrs;
      default = { };
      description = "A set of files to be managed by home-manager's <option>home.file</option>.";
    };

    configFile = lib.mkOption {
      type = attrs;
      default = { };
      description = "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    };

    extraOptions = lib.mkOption {
      type = attrs;
      default = { };
      description = "Options to pass directly to home-manager.";
    };
  };

  config = {
    pagman.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = lib.mkAliasDefinitions options.pagman.home.file;
      xdg.enable = true;
      xdg.configFile = lib.mkAliasDefinitions options.pagman.home.configFile;
    };

    home-manager = {
      useUserPackages = true;

      users.teevik =
        lib.mkAliasDefinitions options.pagman.home.extraOptions;
    };
  };
} 