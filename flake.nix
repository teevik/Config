{
  inputs = {

    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Temporary: Zotero 10 still patches ESR 140 internals, but nixpkgs removed
    # that runtime and switched Zotero to incompatible ESR 153. Pin only the
    # runtime until Zotero's build scripts support the newer ESR.
    nixpkgs-zotero-runtime = {
      url = "github:nixos/nixpkgs/e94cb152ed51bd6e24eb4a41f1460252beb52cd2";
      flake = false;
    };

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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gaze = {
      url = "github:GunduLabs/gaze";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages
    noctalia-official-plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia-community-plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
    determinate-nix.url = "github:DeterminateSystems/nix-src";
    cargo-nix-plugin = {
      # Match the library currently used by master-thesis (resolver API 4).
      url = "github:anthropics/cargo-nix-plugin/191bf8e7bd086e96759362817e4fa6c06fa6359b";
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
      };
    in
    inputs.blueprint {
      inherit inputs;
      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          # Temporary: solidtime-desktop's usocket dependency fails on Electron 42.
          "electron-41.10.6"
          "qtwebengine-5.15.19"
        ];
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };
}
