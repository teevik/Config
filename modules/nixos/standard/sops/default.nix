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
        nix-access-tokens-github = {
          owner = "teevik";
          mode = "0400";
        };
        cachix = { };
        wakatime = {
          owner = "teevik";
          path = "/home/teevik/.wakatime.cfg";
        };
        mercury-ai-token = {
          owner = "teevik";
        };
        gemini-api-key = {
          owner = "teevik";
          mode = "0400";
        };
        brave-api-key = {
          owner = "teevik";
          mode = "0400";
        };
        excalidraw-token = {
          owner = "teevik";
        };
      };
    };
  };
}
