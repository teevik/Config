{ ... }:
{
  config = {
    programs.fish.enable = true;
  };

  config.home = {
    programs.fish.enable = true;

    xdg.configFile."fish/config.fish".source = ./config.fish;
  };
}