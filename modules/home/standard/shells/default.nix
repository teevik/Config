{ config, pkgs, ... }:
{
  programs.nushell = {
    enable = true;

    envFile.source = ./env.nu;
    configFile.source = ./config.nu;
    extraConfig = ''
      $env.config.hooks.command_not_found = source ${pkgs.nix-index}/etc/profile.d/command-not-found.nu
    '';
    environmentVariables = config.home.sessionVariables;
  };

  programs.carapace.enable = true;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting

      bind \b backward-kill-word
      bind \e\[3\;5~ kill-word
    '';
  };
}
