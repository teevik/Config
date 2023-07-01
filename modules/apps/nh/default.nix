{ config, lib, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nh;
in
{
  options.teevik.apps.nh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nh
      '';
    };
  };

  imports = [
    inputs.nh.nixosModules.default
  ];

  config = mkIf cfg.enable {
    environment.sessionVariables.FLAKE = "/home/teevik/Documents/Config";

    nh.enable = true;
  };
}
