{ pkgs, ... }:
let
  kernelPackages = pkgs.linuxPackages_zen;
in {
  imports = [ ./hardware.nix ];

  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  boot.kernelPackages = kernelPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  hardware.nvidia.package = kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;

  programs.hyprland.nvidiaPatches = true;
  home.wayland.windowManager.hyprland.nvidiaPatches = true;
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
