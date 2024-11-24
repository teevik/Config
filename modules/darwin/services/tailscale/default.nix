{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.tailscale;
in
{
  options.teevik.services.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable tailscale
      '';
    };
  };

  config = mkIf cfg.enable
    {
      services.tailscale = {
        enable = true;
      };
    };
}
