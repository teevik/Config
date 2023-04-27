{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      rust-bin.nightly.latest.default
      rust-analyzer
      cargo-watch
    ];
  };
}
