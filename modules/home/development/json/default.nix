{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.json;
in
{
  options.teevik.development.json = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable json
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vscode-langservers-extracted
    ];
  };
}
