{ perSystem, ... }:
{
  imports = [ ../../shared/noctalia-calendar.nix ];

  programs.noctalia = {
    enable = true;
    package = perSystem.self.noctalia;
    # UWSM supplies the graphical session environment to the packaged service.
    systemd.enable = true;
  };

  environment.etc = {
    "noctalia/plugins".source = "${perSystem.self.noctalia}/share/noctalia/plugins";
    "noctalia/wallpaper.png".source = ./hyprland/background.png;
  };
}
