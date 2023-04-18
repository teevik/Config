{ pkgs, ... }:
{
  config.home = {
    programs.git = {
      enable = true;
      userEmail = "teemu.vikoren@gmail.com";
      userName = "teevik";
    };
  };
}
