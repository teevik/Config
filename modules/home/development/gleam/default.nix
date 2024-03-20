{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.gleam;
in
{
  options.teevik.development.gleam = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable gleam
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gleam
      erlang
      rebar3
    ];
  };
}
