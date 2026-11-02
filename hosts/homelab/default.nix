# The homelab repository's own host, evaluated against this flake's inputs, with
# this flake's T3 Code nightly: it bundles the same codex and claude-code builds.
{ flake, inputs, ... }:
{
  class = "nixos";
  value = inputs.homelab.nixosConfigurations.homelab.extendModules {
    modules = [
      (
        { pkgs, ... }:
        {
          homelab.t3code.package = flake.packages.${pkgs.stdenv.hostPlatform.system}.t3code-nightly;
        }
      )
    ];
  };
}
