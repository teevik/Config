{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.steam;
in
{
  options.teevik.apps.steam = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable steam
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${inputs.nix-gaming.packages.${pkgs.system}.proton-ge}";
  };
}
