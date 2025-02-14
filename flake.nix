{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix.url = "https://flakehub.com/f/NixOS/nix/2.tar.gz";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nix-index-database.url = "github:Mic92/nix-index-database";
    roc.url = "github:roc-lang/roc";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    hyprland-contrib.url = "github:hyprwm/contrib";
    helix.url = "github:helix-editor/helix";
    iwmenu.url = "github:e-tho/iwmenu";
    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";
    hyprland.url = "github:hyprwm/hyprland";
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [ "x86_64-linux" ];
    };
}
