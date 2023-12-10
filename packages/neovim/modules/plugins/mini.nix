{ lib, config, ... }:
let
  inherit (lib) types mkOption mkIf mkMerge;
  cfg = config.plugins.mini;
in
{
  options.plugins.mini = {
    animate = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mini.animate
      '';
    };

    comment = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mini.comment
      '';
    };

    pairs = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mini.pairs
      '';
    };

    indentscope = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable mini.indentscope
      '';
    };
  };

  config = mkIf cfg.enable {
    extraConfigLua = mkMerge [
      (mkIf cfg.animate /* lua */ ''
        -- don't use animate when scrolling with the mouse
        local mouse_scrolled = false

        for _, scroll in ipairs({ "Up", "Down" }) do
          local key = "<ScrollWheel" .. scroll .. ">"
          vim.keymap.set({ "", "i" }, key, function()
            mouse_scrolled = true
            return key
          end, { expr = true })
        end

        local animate = require("mini.animate")

        animate.setup({
          resize = {
            timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
          },

          scroll = {
            timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
            subscroll = animate.gen_subscroll.equal({
              predicate = function(total_scroll)
                if mouse_scrolled then
                  mouse_scrolled = false
                  return false
                end
                return total_scroll > 1
              end,
            }),
          },
        })
      '')

      (mkIf cfg.comment /* lua */ ''
        require('mini.comment').setup()
      '')

      (mkIf cfg.pairs /* lua */ ''
        require('mini.pairs').setup()
      '')

      (mkIf cfg.indentscope /* lua */ ''
        require('mini.indentscope').setup({
          symbol = '▎',
        })
      '')
    ];
  };
}
