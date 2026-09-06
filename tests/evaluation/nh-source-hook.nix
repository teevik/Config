# Local nh 4.4.2 patch, selected by the standard apps module.
{
  pkgs ? import ../../packages/nix-lint/pkgs.nix,
}:
pkgs.nh.override {
  nh-unwrapped = pkgs.nh-unwrapped.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./nh-source-hook.patch ];
  });
}
