{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.neovim;
in
{
  options.teevik.development.neovim = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable neovim
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      teevik.neovim
    ];
  };
}
