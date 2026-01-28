{ inputs, pkgs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  config = {
    environment.systemPackages = [
      inputs.agenix.packages.${pkgs.system}.default
    ];

    age = {
      identityPaths = [ "/home/teevik/.ssh/id_rsa" ];

      secrets = {
        tailscale.file = ./tailscale.age;
        nix-access-tokens-github.file = ./nix-access-tokens-github.age;
        cachix.file = ./cachix.age;
        wakatime.file = ./wakatime.age;
        wakatime.owner = "teevik";
        wakatime.path = "/home/teevik/.wakatime.cfg";
      };
    };
  };
}
