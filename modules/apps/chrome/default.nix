{ pkgs, ... }:
{
  config.home = {
    programs.google-chrome-dev = {
      enable = true;
    };
  };
}
