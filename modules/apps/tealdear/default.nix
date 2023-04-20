{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      tealdeer
    ];
  };
}
