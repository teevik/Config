{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # TODO nixos-usntable
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    # chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-apple-silicon.url = "github:nix-community/nixos-apple-silicon";
    nixos-apple-silicon.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Modules
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";

    # Packages
    # nix.url = "https://flakehub.com/f/NixOS/nix/2.tar.gz";
    # hyprland.url = "github:hyprwm/hyprland";
    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";
    iwmenu.url = "github:e-tho/iwmenu";
    # helix.url = "github:helix-editor/helix";
    hyprland-contrib.url = "github:hyprwm/contrib";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    roc.url = "github:roc-lang/roc";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-dram.url = "github:dramforever/nix-dram";
    zed.url = "github:zed-industries/zed";
    titdb.url = "github:GarrettGR/titdb-nix";

    # TODO non aarch64
    marble.url = "git+ssh://git@github.com/teevik/shell.git";
    # marble.url = "path:/home/teevik/Documents/Projects/shell";
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
