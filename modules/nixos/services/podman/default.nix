{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.services.podman;
in
{
  options.teevik.services.podman = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable podman
      '';
    };
  };

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    teevik.user.extraGroups = [ "podman" ];
  };
}
