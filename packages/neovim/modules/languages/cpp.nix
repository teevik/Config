{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.cpp;
in
{
  options.languages.cpp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable cpp
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers = {
      clangd.enable = true;
      cmake.enable = true;
    };
  };
}
