{ config, inputs, pkgs, lib, ... }:
let
  neovim = lib.getExe inputs.neovim.packages.${pkgs.system}.neovim;
  kitty = lib.getExe pkgs.kitty;
  inherit (pkgs) writeScriptBin;
in
{
  home. packages = [
    (writeScriptBin "nvim" /* bash */ ''
      #!/usr/bin/env bash
      if [ $KITTY_WINDOW_ID ]; then
        ${kitty} @ set-spacing padding=0
        ${kitty} @ set-background-opacity 1
      fi

      ${neovim} $1 $2 $3

      if [ $KITTY_WINDOW_ID ]; then
        ${kitty} @ set-spacing padding=10
        ${kitty} @ set-background-opacity ${builtins.toJSON config.teevik.theme.kittyOpacity}
      fi
    '')
  ];

}
