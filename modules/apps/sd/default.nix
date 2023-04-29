{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      sd
    ];
  };
}
