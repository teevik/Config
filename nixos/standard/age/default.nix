{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets = {
        tailscale.file = ./tailscale.age;
        nix-access-tokens-github.file = ./nix-access-tokens-github.age;
        cachix.file = ./cachix.age;
      };
    };
  };
}
