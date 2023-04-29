{ ... }:
{
  config = {
    nix = {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";
        # Deduplicate and optimize nix store
        auto-optimise-store = true;

        substituters = [
          "https://hyprland.cachix.org"
          "https://nix-community.cachix.org/"
          "https://nyx.chaotic.cx"
        ];

        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      # flake-utils-plus
      generateRegistryFromInputs = true;
      generateNixPathFromInputs = true;
      linkInputs = true;
    };
  };
}
