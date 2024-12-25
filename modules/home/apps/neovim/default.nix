{ inputs, config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.neovim;
  neovim = lib.getExe inputs.neovim.packages.${pkgs.system}.neovim;
  kitty = lib.getExe pkgs.kitty;
in
{
  options.teevik.apps.neovim = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable neovim
      '';
    };
  };

  config = mkIf cfg.enable
    {
      home.packages = with pkgs; [
        (writeScriptBin "nvim" /* bash */ ''
          #!/usr/bin/env bash
          if [ $KITTY_WINDOW_ID ]; then
            ${kitty} @ set-spacing padding=0
            ${kitty} @ set-background-opacity 1
          fi

          ${neovim} $1 $2 $3

          if [ $KITTY_WINDOW_ID ]; then
            ${kitty} @ set-spacing padding=10
            ${kitty} @ set-background-opacity ${builtins.toJSON config.teevik.apps.kitty.opacity}
          fi
        '')
      ];
    };
}
