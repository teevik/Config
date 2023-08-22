{ pkgs, ... }: {
  home.stateVersion = "23.11";

  teevik = {
    themes.everforest.enable = true;

    apps = {
      git.enable = true;
      exa.enable = true;
      neofetch.enable = true;
      zellij.enable = true;
    };

    development = {
      direnv.enable = true;
      devenv.enable = true;
      neovim.enable = true;
    };

    shells = {
      fish.enable = true;
      nushell.enable = true;
    };

    xdg.enable = true;
  };

  home.packages = with pkgs; [
    bat
    erdtree
    gcc
    just
    magic-wormhole
    ripgrep
    sd
    tealdeer
    trashy
    watchexec
  ];
}
