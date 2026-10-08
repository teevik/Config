{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Secrets exported to interactive Nushell sessions, as ENV_VAR = secret name.
  # Nix renders the loader so env.nu never repeats secret paths.
  environmentSecrets = {
    MERCURY_AI_TOKEN = "mercury-ai-token";
    EXCALIDRAW_TOKEN = "excalidraw-token";
    GEMINI_API_KEY = "gemini-api-key";
    BRAVE_API_KEY = "brave-api-key";
  };

  exportSecret =
    variable: secret:
    let
      path = config.sops.secrets.${secret}.path;
    in
    ''
      if ("${path}" | path exists) {
          let value = (open --raw "${path}" | str trim)
          if ($value | is-not-empty) {
              $env.${variable} = $value
          }
      }
    '';
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = {
    # Sourced from dotfiles/.config/nushell/env.nu.
    environment.etc."nushell/scripts/secrets.nu".text = lib.concatLines (
      lib.mapAttrsToList exportSecret environmentSecrets
    );

    environment.systemPackages = [
      pkgs.sops
      pkgs.age
    ];

    # On a new machine the age key arrives with the installation seed.
    system.activationScripts.setupSecrets.deps = [ "installSeed" ];

    sops = {
      # Temporary compatibility until sops-nix stops requesting the removed Go 1.25 builder.
      package =
        (pkgs.callPackage inputs.sops-nix {
          pkgs = pkgs.extend (
            _: prev: {
              buildGo125Module = prev.buildGoModule;
            }
          );
        }).sops-install-secrets;

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
