{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.docker;
in
{
  options.teevik.services.docker = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable docker
      '';
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
    };

    teevik.user.extraGroups = [ "docker" ];
  };
}
