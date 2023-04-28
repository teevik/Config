{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      jetbrains.pycharm-professional
    ];
  };
}
