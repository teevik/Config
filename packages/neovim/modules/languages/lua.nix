{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.lua;
in
{
  options.languages.lua = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable lua
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers.lua-ls.enable = true;
  };
}
