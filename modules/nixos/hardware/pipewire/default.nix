{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.hardware.pipewire;
in
{
  options.teevik.hardware.pipewire = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable pipewire
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pulseaudio
    ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
