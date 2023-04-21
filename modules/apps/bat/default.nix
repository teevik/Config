{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      bat
    ];
  };
}
