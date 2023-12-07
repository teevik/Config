{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.lualine;
in
{
  config = mkIf cfg.enable {
    plugins.lualine = {
      globalstatus = true;
    };
  };
}
