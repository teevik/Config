{ config, ... }: {
  home.file.".cargo/config.toml".source = config.lib.file.mkOutOfStoreSymlink "/home/teevik/Documents/Config/modules/home/standard/development/cargo/config.toml";
}
