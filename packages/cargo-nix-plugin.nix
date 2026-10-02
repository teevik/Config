{
  inputs,
  perSystem,
  pkgs,
  ...
}:
# Plugin ABI compatibility requires the exact evaluator selected by nix.package.
(pkgs.callPackage "${inputs.cargo-nix-plugin}/nix/plugin.nix" {
  nixComponents = {
    inherit (perSystem.self.determinate-nix.libs) nix-expr nix-store;
  };
}).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      nix = perSystem.self.determinate-nix;
    };
  })
