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
    home.packages = with pkgs; [
      rustup
      pkg-config
      openssl.dev
      cargo-watch
      lld
      mold
      cargo-wizard
    ];

    home.sessionVariables.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
  };
}
