{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      watchexec
    ];
  };
}
