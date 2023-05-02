{ pkgs, ... }:
let
  kernelPackages = pkgs.linuxPackages_xanmod_latest;
in
{
  imports = [ ./hardware.nix ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  boot.kernelPackages = kernelPackages;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  };

  hardware.nvidia.package = kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;
  programs.hyprland.nvidiaPatches = true;
  teevik.home.wayland.windowManager.hyprland.nvidiaPatches = true;

  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
