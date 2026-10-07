{
  config,
  pkgs,
  ...
}:
{
  programs.nh.package = import ../../../../packages/nh {
    inherit pkgs;
    flake = config.programs.nh.flake;
  };
}
