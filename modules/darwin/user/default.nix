{ config, lib, ... }:

let
  cfg = config.teevik.user;
in
{
  options.teevik.user = with lib.types; {
    extraOptions = lib.mkOption {
      type = attrs;
      default = { };
      description = "Extra options passed to <option>users.users.teevik</option>.";
    };
  };

  config = {
    users.users.teevik = cfg.extraOptions;
  };
}
