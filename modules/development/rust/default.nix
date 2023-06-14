{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    rustup
    pkg-config
    cargo-watch
  ];
}
