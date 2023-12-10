{ pkgs, lib, config, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.languages.nix;
in
{
  options.languages.nix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nix
      '';
    };
  };

  config = mkIf cfg.enable {
    plugins.nix.enable = true;

    plugins.lsp.servers.nil_ls = {
      enable = true;
      settings.formatting.command = [ (lib.getExe pkgs.nixpkgs-fmt) ];
    };
  };
}
