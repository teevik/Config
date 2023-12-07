{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.python;
in
{
  options.languages.python = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable python
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers.pyright.enable = true;
  };
}
