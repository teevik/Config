{ ... }: {
  programs.nushell = {
    enable = true;

    envFile.source = ./env.nu;
    configFile.source = ./config.nu;
  };

  programs.carapace.enable = true;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
    '';
  };
}
