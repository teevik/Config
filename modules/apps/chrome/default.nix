{ pkgs, ... }:
{
  config.pagman.home.extraOptions = {
    programs.google-chrome = {
      enable = true;
    };
  };
}
