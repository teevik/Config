{
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

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

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-system-graphics = {
      url = "github:soupglasses/nix-system-graphics";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    astal = {
      url = "git+ssh://git@github.com/teevik/astal.git?ref=feat/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    marble = {
      url = "git+ssh://git@github.com/teevik/marble-shell.git";
      inputs.astal.follows = "astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages
    determinate-nix.url = "github:DeterminateSystems/nix-src";
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
    openconnect-sso.url = "github:active-group/openconnect-sso";
    nix-dram.url = "github:dramforever/nix-dram";
    titdb = {
      url = "github:GarrettGR/titdb-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    neovim = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zed.url = "github:teevik/zed-cached/stable";

    # opencode = {
    #   url = "github:sst/opencode";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    hyprland-scratchpad = {
      url = "github:teevik/hyprland-scratchpad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Temporary pin: the next commit crashes when xdg-system-bell rings
    # without an associated surface (hyprwm/Hyprland#15502).
    hyprland.url = "github:hyprwm/Hyprland/db95de4f5b4ce446984d873e5b51ebdc380dc76c";
    split-monitor-workspaces = {
      url = "github:zjeffer/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs =
    unpatchedInputs:
    let
      patcher = unpatchedInputs.flake-input-patcher.lib.x86_64-linux;
      inputs = patcher.patch {
        inherit unpatchedInputs;
        flakePath = ./.;

        patchSpec = {
          nixpkgs.patches = [
            (patcher.fetchpatch {
              name = "python3Packages.nanoemoji: fix hash";
              url = "https://github.com/NixOS/nixpkgs/commit/1e544d5f3944e555dd7919258882562e616407a8.patch";
              hash = "sha256-Ccq7SIHk9AS/OXwL55jtVdbH7Wb8aroSS+uXFkWvpNg=";
            })
            (patcher.fetchpatch {
              name = "wf-recorder: pin ffmpeg_8";
              url = "https://github.com/NixOS/nixpkgs/commit/fc31aa40b9bf77889afbcf495f3161a026bcb80a.patch";
              hash = "sha256-yG0OLFacC5GB+BzQM8dnU+ucAak3onaIMmyoxQt3fx0=";
            })
          ];
        };
      };
    in
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "qtwebengine-5.15.19"
        ];
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
