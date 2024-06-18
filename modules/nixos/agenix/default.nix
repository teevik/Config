{ config, inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets = {
        tailscale.file = ./tailscale.age;
        # TEMPORARY
        tailscale.mode = "777";

        healthchecks.file = ./healthchecks.age;
        cachix-agent.file = ./cachix-agent.age;
        nix-access-tokens-github.file = ./nix-access-tokens-github.age;
      };

    };

    nix.extraOptions = ''
      !include ${config.age.secrets.nix-access-tokens-github.path}
    '';
  };
}
