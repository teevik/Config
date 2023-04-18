{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    snowfall-lib.url = "github:snowfallorg/lib/dev";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      channels-config.allowUnfree = true;

      # overlays = with inputs; [
      #   # neovim.overlay
      #   # flake.overlay
      #   # cowsay.overlay
      #   # icehouse.overlay
      # ];

      # systems.modules = with inputs; [
      #   # home-manager.nixosModules.home-manager
      #   # nix-ld.nixosModules.nix-ld
      # ];
    };
}