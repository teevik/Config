{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.odin;
in
{
  options.teevik.development.odin = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable odin
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      odin
      ols
    ];
  };
}
