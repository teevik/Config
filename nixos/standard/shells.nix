{ pkgs, ... }: {
  # Nushell (login shell)
  environment.shells = [ pkgs.nushell ];
  users.users.teevik.shell = pkgs.nushell;

  # Fish
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting
    '';
  };
}
