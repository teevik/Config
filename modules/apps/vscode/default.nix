{ pkgs, ... }:
{
  config.home = {
    programs.vscode = {
      enable = true;
    };
  };
}
