{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.fonts;
in
{
  options.teevik.desktop.fonts = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fonts
      '';
    };
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      jetbrains-mono

      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
        ];
      })
    ];
  };
}
