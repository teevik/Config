{ config, lib, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.teevik.apps.helix;
in
{
  options.teevik.apps.helix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable helix
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;

      settings = {
        theme = "everforest_dark";

        editor = {
          line-number = "relative";
          bufferline = "always";
          color-modes = true;
          auto-save = true;

          scrolloff = 10;
          completion-trigger-len = 1;
          idle-timeout = 100;
        };

        editor.lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        editor.cursor-shape = {
          insert = "bar";
        };

        keys.normal = {
          esc = [ "collapse_selection" "keep_primary_selection" ];
          "C-/" = "toggle_comments";
        };

        keys.insert = {
          "C-s" = ":w";
        };
      };

      # languages = {
      #   language = [{
      #     name = "nix";
      #     language-server = {
      #       command = lib.getExe pkgs.nixd;
      #     };
      #   }];
      # };
    };
  };
}
