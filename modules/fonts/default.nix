{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.fonts;
in
{
  options.teevik.fonts = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable fonts
      '';
    };
  };

  config = mkIf cfg.enable {
    fonts.fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      jetbrains-mono

      (nerdfonts.override {
        fonts = [
          "JetBrainsMono"
        ];
      })
    ];
  };
}
