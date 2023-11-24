{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.cpp;
in
{
  options.teevik.development.cpp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable cpp
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      clang-tools
      lldb
    ];
  };
}
