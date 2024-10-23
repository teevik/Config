{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps._1password;
in
{
  options.teevik.apps._1password = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable _1password
      '';
    };
  };

  config = mkIf cfg.enable {
    programs = {
      _1password.enable = true;
      _1password-gui = {
        enable = true;
        polkitPolicyOwners = [ "teevik" ];
      };
    };
  };
}
