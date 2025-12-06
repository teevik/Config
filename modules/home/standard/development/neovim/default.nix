{
  config,
  pkgs,
  perSystem,
  ...
}:
{
  home.packages = [
    perSystem.neovim.default
    pkgs.unzip
  ];

  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/home/teevik/Documents/Config/modules/home/standard/development/neovim";
}
