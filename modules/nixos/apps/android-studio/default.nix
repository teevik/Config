{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.android-studio;
in
{
  options.teevik.apps.android-studio = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable android-studio
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.adb.enable = true;
    teevik.user.extraGroups = [ "kvm" "adbusers" ];

    environment.systemPackages = [ pkgs.android-studio ];
  };
}
