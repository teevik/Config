{ self, inputs, ... }: {
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen

    "${self}/nixos/standard"
    "${self}/nixos/laptop.nix"
  ];

  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  system.stateVersion = "24.11";
}
