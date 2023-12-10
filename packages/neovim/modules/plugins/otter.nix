{ lib, config, pkgs, ... }:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.plugins.otter;
in
{
  options.plugins.otter = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable otter
      '';
    };
  };

  config = mkIf cfg.enable {
    extraPlugins = with pkgs.vimPlugins; [
      otter-nvim
    ];

    extraConfigLua = /* lua */ ''
      local toggle_otter = function()
        require("otter").activate({"lua", "bash"})
      end

      require('which-key').register({
        t = {
          name = "Toggle",
          o = { toggle_otter, "Otter" },
        },
      }, { mode = "n", prefix = "<leader>", silent = true })
    '';
  };
}
