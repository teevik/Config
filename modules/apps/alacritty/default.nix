{ pkgs, ... }:
{
  config.home = {
    programs.alacritty = {
      enable = true;
    };
  };
}
