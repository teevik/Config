{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.python;
in
{
  options.teevik.development.python = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable python
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      python3
    ];
  };
}
