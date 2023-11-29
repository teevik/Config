{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.neovim;
  neovim = lib.getExe pkgs.neovim;
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
        (writeScriptBin "nvim"
          ''
            #!/usr/bin/env bash
            ${kitty} @ set-spacing padding=0
            ${kitty} @ set-background-opacity 1

            ${neovim} $1 $2 $3

            ${kitty} @ set-spacing padding=10
            ${kitty} @ set-background-opacity 0
          '')
      ];

      # TODO use mkOutOfStoreSymlink once 
      # xdg.configFile = {
      #   "nvim" = {
      #     # source = ./lazy-vim;

      #     source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/Config/modules/home/apps/neovim/lazy-vim";
      #     # recursive = true;
      #   };
      #a

      home.activation.neovim = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ln -s $VERBOSE_ARG \
            ${config.home.homeDirectory}/Documents/Config/modules/home/apps/neovim/lazy-vim \
            ${config.home.homeDirectory}/.config/nvim
      '';
    };
}
