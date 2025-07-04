{
  flake,
  inputs,
  ...
}:
{
  imports = [
    ./hardware.nix
    inputs.nixos-apple-silicon.default

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "macbook";

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  boot.loader.efi.canTouchEfiVariables = false;

  system.stateVersion = "25.11";
}
