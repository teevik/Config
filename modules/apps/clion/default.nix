{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      jetbrains.clion
    ];
  };
}
