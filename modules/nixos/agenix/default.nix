{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets.tailscale.file = ./tailscale.age;
      secrets.healthchecks.file = ./healthchecks.age;
      secrets.wireguard = {
        file = ./wireguard.age;
        name = "wg.conf";
        group = "torrenter";
      };
    };
  };
}
