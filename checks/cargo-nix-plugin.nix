{
  inputs,
  perSystem,
  pkgs,
  ...
}:
# Exercise real workspace resolution with the matching evaluator, so Nix
# package updates catch plugin loading and ABI regressions.
pkgs.callPackage "${inputs.cargo-nix-plugin}/nix/eval-test.nix" {
  plugin = perSystem.self.cargo-nix-plugin;
  nix = perSystem.self.cargo-nix-plugin.nix;
  testFixtures = "${inputs.cargo-nix-plugin}/rust/tests/fixtures";
}
