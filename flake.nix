{
  description = "teevik's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

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
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;
      };
    in
    lib.mkFlake {
      package-namespace = "pagman";

      channels-config.allowUnfree = true;

      overlays = with inputs; [
        # neovim.overlay
        # flake.overlay
        # cowsay.overlay
        # icehouse.overlay
      ];

      systems.modules = with inputs; [
        # home-manager.nixosModules.home-manager
        # nix-ld.nixosModules.nix-ld
      ];
    };
}