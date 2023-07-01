{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.direnv;
in
{
  options.teevik.development.direnv = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable direnv
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
