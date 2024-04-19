{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.go;
in
{
  options.teevik.development.go = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable go
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      go_1_22
      gopls
      delve
    ];
  };
}
