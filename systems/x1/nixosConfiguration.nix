{ self, inputs, ... }: {
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen

    "${self}/nixos/standard"
    "${self}/nixos/laptop.nix"
  ];

  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  virtualisation.vmVariant = {
    # following configuration is added only when building VM with build-vm
    virtualisation = {
      memorySize = 4096; # Use 2048MiB memory.
      diskSize = 8192; # Use 8GiB disk.
      cores = 3;
      writableStoreUseTmpfs = false;
    };
  };

  system.stateVersion = "24.11";
}
