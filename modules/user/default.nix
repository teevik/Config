{ config, lib, pkgs, ... }:

let
  cfg = config.pagman.user;
in
{
  options.pagman.user = with lib.types; {
    extraGroups = lib.mkOption {
      type = listOf str; 
      default = [ ]; 
      description = "Groups for the user to be assigned.";
    };
  };

  config = {
    programs.fish.enable = true;

    users.users.teevik = {
      isNormalUser = true;
      home = "/home/teevik";
      group = "users";

      shell = pkgs.fish;

      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
    };
  };
}