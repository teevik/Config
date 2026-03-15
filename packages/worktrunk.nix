{ pkgs, ... }:
pkgs.worktrunk.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ./worktrunk-nushell-pwd-fix.patch
  ];
})
