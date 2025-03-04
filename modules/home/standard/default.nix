{ ... }:
{
  imports = [
    ./apps
    ./development
    ./shells
    ./theme
    ./xdg.nix
  ];

  # TODO shared with nixos
  nixpkgs.config = {
    allowUnfree = true;
  };

  systemd.user.startServices = "sd-switch";
  home.sessionVariables.EDITOR = "hx";
  programs.man.generateCaches = false;
}
