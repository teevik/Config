{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      trashy
    ];
  };
}