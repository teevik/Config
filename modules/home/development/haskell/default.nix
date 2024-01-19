{ config, lib, pkgs, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.haskell;
in
{
  options.teevik.development.haskell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable haskell
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (haskellPackages.ghcWithPackages (pkgs: with pkgs; [
        stack
        haskell-language-server
        doctest
      ]))
    ];
  };
}
