{ inputs, config, lib, system, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.roc;
  rocPkgs = inputs.roc.packages.${system};
in
{
  options.teevik.development.roc = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable roc
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      rocPkgs.cli
      rocPkgs.lang-server
    ];
  };
}
