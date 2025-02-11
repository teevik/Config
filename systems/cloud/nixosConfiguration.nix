{ self, ... }: {
  imports = [
    ./hardware.nix

    "${self}/nixos/minimal"
    "${self}/nixos/standard"
  ];

  system.stateVersion = "24.11";
}
