{ pkgs }:
pkgs.lix.overrideAttrs (prev: {
  pname = "lix-patched";

  patches =
    (prev.patches or [ ])
    ++ [
      ./lix-default-flake.patch
    ];

  dontCheck = true;
})
