{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.notify;
in
{
  config = mkIf cfg.enable {
    plugins.notify = {
      level = 2;
      topDown = true;
      maxWidth = 400;
    };
  };
}
