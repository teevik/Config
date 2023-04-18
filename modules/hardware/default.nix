{ inputs, ... }:
{
  config = {
    hardware.enableAllFirmware = true;

    programs.light.enable = true;

    user.extraGroups = [ "video" ];
  };
}