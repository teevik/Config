{ config, lib, pkgs, ... }:
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
    environment.systemPackages = with pkgs; [
      haskellPackages.ghc
      haskellPackages.cabal-install
      haskell-language-server
    ];
  };
}
