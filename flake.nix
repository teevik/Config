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

    flake-input-patcher.url = "github:jfly/flake-input-patcher";

    # Modules
    # determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "https://flakehub.com/f/nix-community/disko/1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    marble = {
      url = "git+ssh://git@github.com/teevik/marble-shell.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # marble.url = "path:./marble-shell";
    automatic-sunset = {
      url = "github:teevik/automatic-sunset";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    iwmenu = {
      url = "github:e-tho/iwmenu";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openconnect-sso.url = "github:ThinkChaos/openconnect-sso/fix/nix-flake";
    roc.url = "github:roc-lang/roc";
    nix-dram.url = "github:dramforever/nix-dram";
    zed = {
      url = "github:zed-industries/zed/nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    titdb = {
      url = "github:GarrettGR/titdb-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # opencode = {
    #   url = "github:sst/opencode";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    hyprland-scratchpad = {
      url = "github:teevik/hyprland-scratchpad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs =
    unpatchedInputs:
    let
      patcher = unpatchedInputs.flake-input-patcher.lib.x86_64-linux;
      inputs = patcher.patch unpatchedInputs {
        nixpkgs.patches = [
          (patcher.fetchpatch {
            name = "python3Packages.picosvg: fix test failures";
            url = "https://github.com/nixos/nixpkgs/pull/493376.diff";
            hash = "sha256-Yn5CGPnk+oW1F19qlp/Y6sn7bM6Mf+2UYPOEIjPtYtg=";
          })
          (patcher.fetchpatch {
            name = "python3Packages.jupytext: fix test failures";
            url = "https://github.com/nixos/nixpkgs/pull/493542.diff";
            hash = "sha256-TcMPseIYN5v/ZyO/38YhGIkz25wwSjLSvR1BSdCMyoI=";
          })
        ];
      };
    in
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config.allowUnfree = true;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
