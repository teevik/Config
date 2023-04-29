{ pkgs, ... }:
{


  config = {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };

    chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];
  };
}
