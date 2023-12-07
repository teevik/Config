{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.which-key;
in
{
  config = mkIf cfg.enable {
    plugins.which-key = {
      window.winblend = 10;
    };
  };
}
