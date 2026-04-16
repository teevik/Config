{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulseaudio
    pavucontrol
    pulsemixer
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    wireplumber.extraConfig = {
      # Audeze Maxwell dongle: prevent race condition when headphones are turned
      # on while audio is already playing. Without this, the device nodes get
      # suspended/paused and fail to initialize properly on hot-plug.
      "audeze-maxwell" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.usb-Audeze_LLC_Audeze_Maxwell_.*"; }
              { "node.name" = "~alsa_input.usb-Audeze_LLC_Audeze_Maxwell_.*"; }
            ];
            actions."update-props" = {
              "node.pause-on-idle" = false;
              "session.suspend-timeout-seconds" = 0;
            };
          }
        ];
      };
    };
  };

  # Tell PipeWire to use the gaming headset profile for Audeze Maxwell.
  # This gives proper FL/FR channel maps instead of AUX0/AUX1, and improves
  # hot-plug behavior when audio is already playing.
  # Run `lsusb` with headphones ON to verify idProduct for your dongle variant
  # (Xbox dongle = 4b18, other variants may differ).
  services.udev.extraRules = ''
    ATTRS{idVendor}=="3329", ENV{ACP_PROFILE_SET}="usb-gaming-headset.conf"
  '';
}
