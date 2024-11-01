{ pkgs, config, lib, inputs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.nwg-displays;
in
{
  options.teevik.apps.nwg-displays = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nwg-displays
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # nwg-displays
      # TODO use stable
      (inputs.nixpkgs-unstable-unfree.legacyPackages.${pkgs.system}.nwg-displays)
    ];

    home.activation.myNwgDisplay = lib.home-manager.hm.dag.entryAfter [ "writeBoundary" ] ''
      run [ -f ~/.config/hypr/monitors.conf ] || touch ~/.config/hypr/monitors.conf
      run [ -f ~/.config/hypr/workspaces.conf ] || touch ~/.config/hypr/workspaces.conf
    '';

    wayland.windowManager.hyprland.settings = {
      source = [
        "~/.config/hypr/monitors.conf"
        "~/.config/hypr/workspaces.conf"
      ];
    };
  };
}
