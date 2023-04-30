{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      flyctl
    ];
  };
}
