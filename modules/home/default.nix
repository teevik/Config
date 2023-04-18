{ options, config, inputs, ... }:
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.pagman.home = with lib.types; {
    file = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOption {
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
        mkAliasDefinitions options.pagman.home.extraOptions;
    };
  };
} 