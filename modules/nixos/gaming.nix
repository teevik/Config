{ pkgs, ... }:
let
  dualsense-udev = pkgs.writeTextDir "etc/udev/rules.d/70-dualsensectl.rules" ''
    # PS5 DualSense controller over USB hidraw
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"
    # PS5 DualSense controller over bluetooth hidraw
    KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"
    # PS5 DualSense Edge controller over USB hidraw
    KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"
    # PS5 DualSense Edge controller over bluetooth hidraw
    KERNEL=="hidraw*", KERNELS=="*054C:0DF2*", MODE="0660", TAG+="uaccess"
  '';
in
{
  # Steam and Lutris
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  environment.systemPackages = with pkgs; [
    lutris
    dualsensectl
    (prismlauncher.override {
      jdks = with pkgs; [
        jdk25
        jdk21
        jdk17
        jdk8
      ];
    })
  ];

  # services = {
  #   udev = {
  #     packages = with pkgs; [
  #       game-devices-udev-rules
  #     ];
  #   };
  # };

  services.udev.packages = [ dualsense-udev ];
  hardware.uinput.enable = true;
}
