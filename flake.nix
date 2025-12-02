{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-unfree = {
      url = "github:numtide/nixpkgs-unfree";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Modules
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    marble.url = "git+ssh://git@github.com/teevik/shell.git";
    automatic-sunset.url = "github:teevik/automatic-sunset";
    niri.url = "github:sodiboo/niri-flake";

    # Packages
    determinate-nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";
    iwmenu.url = "github:e-tho/iwmenu";
    helix.url = "github:helix-editor/helix";
    hyprland-contrib.url = "github:hyprwm/contrib";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    roc.url = "github:roc-lang/roc";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-dram.url = "github:dramforever/nix-dram";
    zed.url = "github:zed-industries/zed/nightly";
    titdb.url = "github:GarrettGR/titdb-nix";
    nix-userstyles.url = "github:knoopx/nix-userstyles";
    nwg-display.url = "github:nwg-piotr/nwg-displays";
    antigravity.url = "github:jacopone/antigravity-nix";
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
