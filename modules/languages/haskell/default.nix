{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    haskellPackages.ghc
    haskellPackages.cabal-install
    haskell-language-server
  ];
}
