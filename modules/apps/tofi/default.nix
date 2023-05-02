{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tofi
  ];

  teevik.home = {
    xdg.configFile."tofi/config".source = ./config;
  };
}
