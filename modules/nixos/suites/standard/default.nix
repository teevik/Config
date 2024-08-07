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
        nautilus.enable = true;
      };
    };

    programs = {
      _1password.enable = true;
      _1password-gui.enable = true;
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
