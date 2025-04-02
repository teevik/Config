{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    iosevka
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    jetbrains-mono

    # (nerdfonts.override {
    #   fonts = [
    #     "JetBrainsMono"
    #     "Ubuntu"
    #     "FiraCode"
    #   ];
    # })
    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.fira-code
    source-sans
  ];
}
