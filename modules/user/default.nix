{ config, lib, pkgs, ... }:

let
  cfg = config.teevik.user;
in
{
  options.teevik.user = with lib.types; {
    extraGroups = lib.mkOption {
      type = listOf str;
      default = [ ];
      description = "Groups for the user to be assigned.";
    };

    extraOptions = lib.mkOption {
      type = attrs;
      default = { };
      description = "Extra options passed to <option>users.users.teevik</option>.";
    };
  };

  config = {
    users.users.teevik = {
      isNormalUser = true;
      home = "/home/teevik";
      group = "users";

      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}
