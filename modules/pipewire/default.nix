{ pkgs, ... }:
{
  config = {
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
