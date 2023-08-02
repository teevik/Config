{ config, pkgs, ... }:
{
  config = {
    teevik = {
      hardware = {
        networking.enable = true;
        firmware.enableAllFirmware = true;
      };

      apps = {
        git.enable = true;
        comma.enable = true;
      };

      services = {
        autologin.enable = true;
      };
    };

    system.nixos.variant_id = "installer";
    isoImage.isoName = "nixos-minimal-${config.system.nixos.release}-${pkgs.stdenv.hostPlatform.system}.iso";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };
}
