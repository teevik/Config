{ pkgs, ... }: {
  # Steam and Lutris
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "${pkgs.proton-ge-bin}";

  environment.systemPackages = with pkgs; [
    lutris
  ];
}
