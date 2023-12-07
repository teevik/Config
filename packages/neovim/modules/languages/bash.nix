{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.bash;
in
{
  options.languages.bash = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable bash
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers.bashls.enable = true;
  };
}
