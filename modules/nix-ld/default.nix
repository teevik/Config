{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.nix-ld;
in
{
  options.teevik.nix-ld = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable nix-ld
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;

      libraries = with pkgs; [
        stdenv.cc.cc
        fuse3
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        curl
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        libGL
        libappindicator-gtk3
        libdrm
        libnotify
        libpulseaudio
        libuuid
        libusb1
        xorg.libxcb
        libxkbcommon
        mesa
        nspr
        nss
        pango
        pipewire
        systemd
        icu
        openssl
        xorg.libX11
        xorg.libXScrnSaver
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXi
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libxkbfile
        xorg.libxshmfence
        zlib
      ];
    };
  };
}
