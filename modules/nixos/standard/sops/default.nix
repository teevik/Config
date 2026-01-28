{ inputs, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = {
    environment.systemPackages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.keyFile = "/home/teevik/.config/sops/age/keys.txt";

      secrets = {
        tailscale = { };
        nix-access-tokens-github = { };
        cachix = { };
        wakatime = {
          owner = "teevik";
          path = "/home/teevik/.wakatime.cfg";
        };
        github-runner-token = {
          owner = "github-runner";
        };
      };
    };
  };
}
