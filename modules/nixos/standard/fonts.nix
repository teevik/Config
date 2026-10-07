{ pkgs, perSystem, ... }:
{
  fonts.packages = with pkgs; [
    iosevka
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    jetbrains-mono

    nerd-fonts.jetbrains-mono
    nerd-fonts.ubuntu
    nerd-fonts.fira-code
    source-sans
    perSystem.self.google-sans-flex
  ];
}
