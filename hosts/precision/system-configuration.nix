{ inputs, flake, ... }:
{
  imports = [
    inputs.nix-system-graphics.systemModules.default
    # flake.modules.shared.packages
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config = {
    allowUnfree = true;
  };

  system-manager.allowAnyDistro = true;
  system-graphics.enable = true;

  systemd.globalEnvironment = {
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };
}
