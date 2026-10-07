{ pkgs, ... }:
(import ../nu-scripts/write-application.nix { inherit pkgs; }) {
  name = "fox";
  # `op` and `ssh` stay the system ones: the 1Password wrapper needs polkit, ssh the user's config.
  runtimeInputs = [ pkgs.expect ];
  script = ./fox.nu;
}
