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
      biome
      emmet-ls
      nodePackages.typescript-language-server
      nodePackages."@prisma/language-server"

      yarn
    ];

    home.file.".npmrc".text = ''
      prefix=~/.npm-packages
      audit=false
    '';

    home.activation.npm-packages = lib.home-manager.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/.npm-packages/lib
    '';
  };
}
