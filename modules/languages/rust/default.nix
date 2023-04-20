{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      pkgs.rust-bin.stable.latest.default
      # rust-bin.selectLatestNightlyWith (toolchain: toolchain.default)
    ];
  };
}
