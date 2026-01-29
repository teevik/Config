{ flake, ... }:
{
  imports = [
    flake.homeModules.standard
    flake.homeModules.linux
    # flake.homeModules.ctf
  ];

  # Disable userstyles to avoid IFD during cross-architecture evaluation
  # (checking aarch64-linux configs on x86_64-linux fails otherwise)
  teevik.firefox.enableUserStyles = false;

  home.stateVersion = "25.05";
}
