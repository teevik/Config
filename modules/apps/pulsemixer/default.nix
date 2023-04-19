{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      pulsemixer
    ];
  };
}
