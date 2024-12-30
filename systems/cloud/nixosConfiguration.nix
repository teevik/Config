{ self, ... }: {
  imports = [
    ./hardware.nix

    "${self}/nixos/standard"
  ];

  system.stateVersion = "24.11";
}
