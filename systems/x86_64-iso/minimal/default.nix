{ ... }:
{
  teevik = {
    networking.enable = true;

    hardware.firmware.enableAllFirmware = true;

    apps = {
      git.enable = true;
    };

    services = {
      autologin.enable = true;
    };

    user.extraOptions = {
      password = "shrekshrek";
    };
  };

  users.users.root.password = "shrekshrek";

  system.nixos.variant_id = "installer";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
