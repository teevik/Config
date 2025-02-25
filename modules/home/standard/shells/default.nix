{ config, ... }:
{
  programs.nushell = {
    enable = true;

    envFile.source = ./env.nu;
    configFile.source = ./config.nu;
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
