{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.web;
in
{
  options.languages.web = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable web
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers = {
      html.enable = true;
      jsonls.enable = true;
      tailwindcss.enable = true;
      tsserver.enable = true;
      yamlls.enable = true;
    };
  };
}
