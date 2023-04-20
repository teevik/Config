{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      tofi
    ];
  };
}
