{ config, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/all-hardware.nix"
    "${modulesPath}/profiles/base.nix"
  ];

  config = {
    teevik = {
      hardware = {
        networking.enable = true;
        firmware.enableAllFirmware = true;
      };

      apps = {
        git.enable = true;
      };

      services = {
        autologin.enable = true;
      };
    };

    # boot.loader.grub.memtest86.enable = true;

    system.nixos.variant_id = "installer";
    isoImage.isoName = "nixos-minimal-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.system}.iso";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };
}
