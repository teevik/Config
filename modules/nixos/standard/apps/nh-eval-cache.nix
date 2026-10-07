{
  config,
  pkgs,
  ...
}:
{
  programs.nh.package = import ../../../../packages/nh {
    inherit pkgs;
  };

  # Keep NH_FLAKE writable for updates; prepare a fresh snapshot on each rebuild.
  environment.variables.NH_OS_FLAKE_SOURCE_COMMAND = "${config.programs.nh.flake}/packages/nh/prepare-source";
}
