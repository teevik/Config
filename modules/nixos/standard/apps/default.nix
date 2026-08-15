{
  config,
  pkgs,
  ...
}:
{
  imports = [
    # ./android-studio.nix
    ./nautilus.nix
    ./firefox.nix
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  programs = {
    _1password.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "teevik" ];
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        hyprland
        stdenv.cc.cc.lib
        zlib
        # glib.dev
        # pango.dev
        # gtk3
        # cairo.dev
      ];
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 14d --keep 7";
      flake = "${config.users.users.teevik.home}/Documents/Config";
    };
  };

  services.fwupd.enable = true;
  services.envfs.enable = true;
}
