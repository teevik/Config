{ config, lib, pkgs, ... }:

let
  initialHashedPassword = "$6$X19Q8OhBkw8xUegs$prAFssd1NxBR1qrdMUhqZX4Xqy02bTeNfCZw24YCMClQhp8Pox65w6PF5w7hV2foKfGytsXTwCB5pQ7FLwF7o/";
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

      inherit initialHashedPassword;
    } // cfg.extraOptions;

    users.users.root = {
      inherit initialHashedPassword;
    };
  };
}
