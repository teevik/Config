{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.zig;
in
{
  options.teevik.development.zig = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable zig
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zig
    ];
  };
}
