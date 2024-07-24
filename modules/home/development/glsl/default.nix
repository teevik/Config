{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.glsl;
in
{
  options.teevik.development.glsl = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable glsl
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      glsl_analyzer
    ];
  };
}
