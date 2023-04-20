{ pkgs, ... }:
{
  config.home = {
    programs.helix = {
      enable = true;
    };
  };
}
