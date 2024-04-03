{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets = {
        tailscale.file = ./tailscale.age;
        healthchecks.file = ./healthchecks.age;
        cachix-agent.file = ./cachix-agent.age;
      };
    };
  };
}
