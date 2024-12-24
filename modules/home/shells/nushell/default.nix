{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.shells.nushell;
  dotfilesPath = "${config.home.homeDirectory}/Documents/Config";
in
{
  options.teevik.shells.nushell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nushell
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.nushell = {
      enable = true;


      # # TODO check if needed
      # environmentVariables = builtins.mapAttrs (name: value: "\"${builtins.toString value}\"") config.home.sessionVariables;
      environmentVariables = builtins.mapAttrs (name: value: "${builtins.toString value}") config.home.sessionVariables;

      loginFile.text = /* nu */ ''
        if (tty) == "/dev/tty1" {
          Hyprland
        }
      '';

      envFile.source = ./env.nu;
      configFile.source = ./config.nu;

      # envFile.text = ''
      #   source ${dotfilesPath}/modules/home/shells/nushell/env.nu
      # '';

      # configFile.text = ''
      #   source ${dotfilesPath}/modules/home/shells/nushell/config.nu
      # '';
    };
  };
}
