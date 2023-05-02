{ ... }:
{
  programs.fish.enable = true;

  teevik.home = {
    programs.fish = {
      enable = true;

      shellInit = ''
        set fish_greeting

        bind \b backward-kill-word
        bind \e\[3\;5~ kill-word
      '';

      shellAbbrs = {
        cat = "bat";
        ls = "exa";
      };
    };
  };
}
