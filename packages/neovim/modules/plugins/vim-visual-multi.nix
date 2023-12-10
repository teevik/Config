{ lib, config, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.plugins.vim-visual-multi;
in
{
  options.plugins.vim-visual-multi = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable vim-visual-multi
      '';
    };
  };

  config = mkIf cfg.enable {
    extraPlugins = with pkgs.vimPlugins; [
      vim-visual-multi
    ];

    extraConfigVim = /* vim */ ''
      let g:VM_mouse_mappings = 1
    '';
  };
}
