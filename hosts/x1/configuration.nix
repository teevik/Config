{
  flake,
  inputs,
  ...
}:
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-7th-gen

    flake.nixosModules.minimal
    flake.nixosModules.standard
    flake.nixosModules.laptop
  ];

  networking.firewall.allowedTCPPorts = [ 9001 ];

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "x1";
  disko.devices = import ./disk-config.nix { disks = [ "/dev/nvme0n1" ]; };

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services = {
    blueman.enable = true;

    hypridle.settings = {
      general = {
        before_sleep_cmd = "hyprctl dispatch dpms off";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  system.stateVersion = "24.11";
}
