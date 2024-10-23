{ pkgs, config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.suites.standard;
in
{
  options.teevik.suites.standard = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable standard suite
      '';
    };
  };

  config = mkIf cfg.enable {
    teevik = {
      desktop = {
        fonts.enable = true;
        hyprland.enable = true;
        i3.enable = true;
      };

      hardware = {
        networking.enable = true;
        pipewire.enable = true;
        firmware.enableAllFirmware = true;
        opengl.enable = true;
      };

      services = {
        autologin.enable = true;
        flatpak.enable = true;
        podman.enable = true;
        tailscale.enable = true;
        polkit.enable = true;
      };

      shells = {
        fish.enable = true;
      };

      apps = {
        _1password.enable = true;
        nautilus.enable = true;
        firefox.enable = true;
        android-studio.enable = true;
      };
    };

    programs = {
      nix-ld.enable = true;
    };

    services.fwupd.enable = true;

    teevik.user.extraOptions.shell = pkgs.fish;

    environment.systemPackages = with pkgs; [
      networkmanagerapplet
      pavucontrol
      pulsemixer
    ];
  };
}
