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

  imports = [ inputs.nix-index-database.hmModules.nix-index ];

  config = mkIf cfg.enable {

    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
  };
}
