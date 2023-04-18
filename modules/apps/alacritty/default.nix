{ pkgs, ... }:
{
  config.pagman.home.extraOptions = {
    programs.alacritty = {
      enable = true;
    };
  };
}
