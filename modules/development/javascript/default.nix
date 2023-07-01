{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.javascript;
in
{
  options.teevik.development.javascript = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable javascript
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nodejs
    ];
  };
}
