{ pkgs, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-21.4.0"
  ];

  environment.systemPackages = with pkgs; [
    obsidian
  ];
}
