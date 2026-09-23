{
  programs.noctalia = {
    enable = true;
    # UWSM supplies the graphical session environment to the packaged service.
    systemd.enable = true;
  };
}
