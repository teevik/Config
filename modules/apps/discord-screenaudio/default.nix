{ lib, pkgs, ... }:
{
  config = {
    # environment.systemPackages = (with lib; filter isDerivation (attrValues (pkgs.libsForQt5.callPackage ./package.nix { })));
    
    environment.systemPackages = [
      # pkgs.libsForQt5.callPackage ./package.nix { } 
      pkgs.teevik.discord-screenaudio
    ];
  };
}
