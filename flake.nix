{
  inputs = {
    self.submodules = true;

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

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Modules
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    agenix.url = "https://flakehub.com/f/ryantm/agenix/0.15.tar.gz";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko.url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
    marble.url = "git+ssh://git@github.com/teevik/marble-shell.git";
    # marble.url = "path:./marble-shell";
    automatic-sunset.url = "github:teevik/automatic-sunset";
    selfhostblocks = {
      url = "github:ibizaman/selfhostblocks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages
    determinate-nix.url = "https://flakehub.com/f/DeterminateSystems/nix-src/*";
    iwmenu.url = "github:e-tho/iwmenu";
    helix.url = "github:helix-editor/helix";
    hyprland-contrib.url = "github:hyprwm/contrib";
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    roc.url = "github:roc-lang/roc";
    nix-dram.url = "github:dramforever/nix-dram";
    zed.url = "github:zed-industries/zed/nightly";
    titdb.url = "github:GarrettGR/titdb-nix";
    antigravity.url = "github:jacopone/antigravity-nix";
    neovim.url = "github:nix-community/neovim-nightly-overlay";
    opencode.url = "github:sst/opencode";
    hyprland-scratchpad.url = "github:teevik/hyprland-scratchpad";

    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
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
