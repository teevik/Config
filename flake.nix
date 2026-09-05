{
  inputs = {

    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
    cargo-nix-plugin = {
      url = "github:anthropics/cargo-nix-plugin";
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
    titdb = {
      url = "github:GarrettGR/titdb-nix";
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
      # Re-evaluate only the two Zed flakes, preserving their locked sources
      # and dependency sets (and therefore their binary-cache compatibility).
      withInputs =
        flake: overrides:
        let
          inputs = flake.inputs // overrides;
          outputs = (import (flake.outPath + "/flake.nix")).outputs (inputs // { self = result; });
          result = flake // outputs // { inherit inputs outputs; };
        in
        result;
      upstreamZed = unpatchedInputs.zed.inputs.zed;
      crane = upstreamZed.inputs.crane;
      pinnedCrane = crane // {
        mkLib =
          pkgs:
          (crane.mkLib pkgs).overrideScope (
            _final: prev: {
              downloadCargoPackageFromGit =
                args:
                let
                  ref = args.ref or null;
                  allRefs = args.allRefs or (ref == null);
                in
                prev.downloadCargoPackageFromGit (
                  args
                  // pkgs.lib.optionalAttrs (ref == null && allRefs) {
                    # Cargo.lock pins the commit; don't resolve remote HEAD.
                    ref = args.rev;
                    allRefs = true;
                  }
                );
            }
          );
      };
      inputs = unpatchedInputs // {
        # The public packages set eagerly filters the whole catalog by
        # platform. Use its lazy constructor with the SAME upstream pkgs,
        # not our system pkgs, to preserve all selected package derivations.
        llm-agents = unpatchedInputs.llm-agents // {
          packages = builtins.mapAttrs (
            system: _:
            let
              upstream = unpatchedInputs.llm-agents;
              pkgs = import upstream.inputs.nixpkgs { inherit system; };
            in
            (upstream.overlays.shared-nixpkgs pkgs pkgs).llm-agents
          ) unpatchedInputs.llm-agents.packages;
        };
        zed = withInputs unpatchedInputs.zed {
          zed = withInputs upstreamZed { crane = pinnedCrane; };
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
