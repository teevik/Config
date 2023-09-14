{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nix-alien;
in
{
  options.teevik.apps.nix-alien = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nix-alien
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      inputs.nix-alien.packages.${pkgs.system}.nix-alien
    ];
  };
}
