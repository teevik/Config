{ inputs, pkgs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets.tailscale.file = ./tailscale.age;
    };
  };
}