{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.bufferline;
in
{
  config = mkIf cfg.enable {
    plugins.bufferline = {
      offsets = [
        {
          filetype = "NvimTree";
          text = "NvimTree";
          highlight = "Directory";
          textAlign = "left";
        }
      ];
    };
  };
}
