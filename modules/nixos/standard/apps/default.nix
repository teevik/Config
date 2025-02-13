{ config, pkgs, ... }: {
  imports = [
    ./nautilus.nix
    ./firefox.nix
    # ./android-studio.nix
  ];

  programs = {
    _1password.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "teevik" ];
    };

    nix-ld.enable = true;

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "${config.users.users.teevik.home}/Documents/Config";
    };
  };

  environment.systemPackages = [
    pkgs.git
    config.boot.kernelPackages.perf
  ];

  services.fwupd.enable = true;
}
