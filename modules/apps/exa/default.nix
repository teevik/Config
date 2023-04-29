{ pkgs, ... }:
{
  config.home = {
    programs.exa = {
      enable = true;

      git = true;

      icons = true;
    };
  };
}
