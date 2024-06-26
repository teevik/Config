{ inputs, pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.devenv;
in
{
  options.teevik.development.devenv = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable devenv
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      devenv
    ];
  };
}
