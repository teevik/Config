{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.haskell;
in
{
  options.languages.haskell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable haskell
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers = {
      hls.enable = true;
    };
  };
}
