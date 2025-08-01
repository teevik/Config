{ ... }:
{
  symlinkToConfig =
    config: path: config.lib.file.mkOutOfStoreSymlink ("/home/teevik/Documents/Config/" + path);
}
