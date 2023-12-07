{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.plugins.noice;
in
{
  config = mkIf cfg.enable {
    plugins.noice = {
      presets = {
        command_palette = true;
        lsp_doc_border = false;
        long_message_to_split = true;
      };
    };
  };
}
