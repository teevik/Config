{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      ripgrep
      ripgrep-all
    ];
  };
}
