{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.go;
in
{
  options.languages.go = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable go
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers.gopls.enable = true;
  };
}
