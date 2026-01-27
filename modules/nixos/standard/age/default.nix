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
        eduroam.file = ./eduroam.age;
        eduroam.path = "/var/lib/iwd/eduroam.8021x";
        eduroam-ca.file = ./eduroam-ca.age;
        eduroam-ca.path = "/var/lib/iwd/eduroam-ca.pem";
        supermemory-api-key.file = ./supermemory-api-key.age;
        supermemory-api-key.owner = "teevik";
        wakatime.file = ./wakatime.age;
        wakatime.owner = "teevik";
        wakatime.path = "/home/teevik/.wakatime.cfg";
        opencode-zen.file = ./opencode-zen.age;
        cloudflare.file = ./cloudflare.age;
      };
    };
  };
}
