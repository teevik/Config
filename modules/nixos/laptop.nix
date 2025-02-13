{ ... }: {
  # Suspend when the lid is closed, then hibernate after 1 hour
  services.logind.lidSwitch = "suspend-then-hibernate";
  systemd.sleep.extraConfig = "HibernateDelaySec=1h";

  # auto-cpufreq for power management
  services.auto-cpufreq.enable = true;

  # Backlight control
  programs.light.enable = true;
  users.users.teevik.extraGroups = [ "video" ];
}
