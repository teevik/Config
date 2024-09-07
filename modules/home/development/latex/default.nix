{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.latex;
in
{
  options.teevik.development.latex = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable latex
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      texlive.combined.scheme-full
      python312Packages.pygments
    ];
  };
}
