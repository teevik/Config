{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      python3
    ];
  };
}
