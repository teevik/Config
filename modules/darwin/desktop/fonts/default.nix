{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.desktop.fonts;
in {
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
    fonts.fontDir.enable = true;
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
