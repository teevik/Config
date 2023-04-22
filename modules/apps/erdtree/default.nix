{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      erdtree
    ];
  };
}
