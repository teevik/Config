{
  inputs,
  perSystem,
  ...
}:
{
  home.packages = [
    perSystem.nwg-display.default
  ];

  home.activation.myNwgDisplay = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run [ -f ~/.config/hypr/monitors.conf ] || touch ~/.config/hypr/monitors.conf
    run [ -f ~/.config/hypr/workspaces.conf ] || touch ~/.config/hypr/workspaces.conf
  '';

  wayland.windowManager.hyprland.settings = {
    source = [
      "~/.config/hypr/monitors.conf"
      "~/.config/hypr/workspaces.conf"
    ];
  };
}
