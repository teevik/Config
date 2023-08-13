{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.nix-daemon;
in
{
  options.teevik.services.nix-daemon = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nix-daemon
      '';
    };
  };

  config = mkIf cfg.enable {
    services.nix-daemon.enable = true;
  };
}
