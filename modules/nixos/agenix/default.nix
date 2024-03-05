{ inputs, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
in
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.system}.default
    ];

    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets.tailscale.file = ./tailscale.age;
    };
  };
}
