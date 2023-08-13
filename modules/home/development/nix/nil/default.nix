{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.nix.nil;
in
{
  options.teevik.development.nix.nil = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nil
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nil
    ];
  };
}
