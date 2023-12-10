{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.rust;
in
{
  options.languages.rust = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable rust
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.lsp.servers.rust-analyzer = {
      enable = true;
      installCargo = false;
      installRustc = false;
    };

    plugins.crates-nvim.enable = true;
  };
}
