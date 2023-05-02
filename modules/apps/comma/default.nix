{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      comma
    ];
  };
}
