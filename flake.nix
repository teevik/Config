{
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # TODO nixos-usntable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    unstable.url = "github:numtide/nixpkgs-unfree/nixos-unstable";
    # chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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
    nix.url = "https://flakehub.com/f/NixOS/nix/2.tar.gz";
    hyprland.url = "github:hyprwm/hyprland";
    betterfox.url = "github:HeitorAugustoLN/betterfox-nix";
    iwmenu.url = "github:e-tho/iwmenu";
    # helix.url = "github:helix-editor/helix";
    hyprland-contrib.url = "github:hyprwm/contrib";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    roc.url = "github:roc-lang/roc";
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-dram.url = "github:dramforever/nix-dram";
    mcp-nixos.url = "github:utensils/mcp-nixos";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    marble = {
      url = "git+ssh://git@github.com/marble-shell/shell.git";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    morewaita = {
      url = "github:somepaulo/MoreWaita";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [ "x86_64-linux" ];
    };
}
