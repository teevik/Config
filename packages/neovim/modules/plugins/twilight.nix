{ lib, config, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.plugins.twilight;
in
{
  options.plugins.twilight = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable twilight
      '';
    };
  };

  config = mkIf cfg.enable {
    extraPlugins = with pkgs.vimPlugins; [
      twilight-nvim
    ];

    extraConfigLua = ''
      require("twilight").setup({})

      require("which-key").register({
        t = {
          name = "Toggle",
          t = { "<cmd>Twilight<cr>", "Toggle twilight" }
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';
  };
}
