{ config, lib, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.comma;
in
{
  options.teevik.apps.comma = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable comma
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik.home = {
      imports = [
        inputs.nix-index-database.hmModules.nix-index
      ];

      programs.nix-index.enable = true;
      programs.nix-index-database.comma.enable = true;
    };
  };
}
