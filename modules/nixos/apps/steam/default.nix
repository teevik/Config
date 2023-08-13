{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.steam;
in
{
  imports = [ inputs.chaotic.nixosModules.default ];

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

    chaotic.steam.extraCompatPackages = [ inputs.chaotic.packages.${pkgs.system}.proton-ge-custom ];
  };
}
