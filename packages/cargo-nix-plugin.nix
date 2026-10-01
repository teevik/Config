{
  inputs,
  perSystem,
  pkgs,
  ...
}:
# Plugin ABI compatibility requires the exact evaluator selected by nix.package.
(pkgs.callPackage "${inputs.cargo-nix-plugin}/nix/plugin.nix" {
  nixComponents = {
    inherit (perSystem.determinate-nix) nix-expr nix-store;
  };
}).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      nix = perSystem.determinate-nix.default;
    };
  })
