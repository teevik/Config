{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.cachix-agent;
in
{
  options.teevik.services.cachix-agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable cachix-agent
      '';
    };
  };

  config = mkIf cfg.enable {
    services.cachix-agent = {
      enable = true;
      credentialsFile = config.age.secrets.cachix-agent.path;
    };
  };
}
