{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.development.javascript;
in
{
  options.teevik.development.javascript = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable javascript
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs
      bun
      typescript
      nodePackages.typescript-language-server
    ];

    home.file.".npmrc".text = ''
      prefix=~/.npm-packages
      audit=false
      loglevel=silent
    '';
  };
}
