{ lib, pkgs, ... }:
let
  inherit (lib) types mkOption;
in
{
  # TODO actual type
  options.teevik.theme = mkOption {
    type = types.attrs;
  };

  config.teevik.theme = import ./catppuccin-mocha { inherit lib pkgs; };
}
