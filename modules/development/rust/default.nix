{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.rust;
in
{
  options.teevik.development.rust = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable rust
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustup
      pkg-config
      cargo-watch
    ];
  };
}
