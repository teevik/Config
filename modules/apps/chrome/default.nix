{ pkgs, ... }:
{
  config.home = {
    programs.google-chrome = {
      enable = true;
    };
  };
}
