{ pkgs, ... }:
{
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "Hibernate";
  };

  # Backlight control
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
