{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.standard;
in
{
  options.teevik.suites.standard = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable standard suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      desktop = {
        fonts.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      services = {
        nix-daemon.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
    ];
  };
}
