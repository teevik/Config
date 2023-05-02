{ ... }:
let
  font = "JetBrainsMono Nerd Font";
  opacity = 0.2;
  size = 13;
in
{
  teevik.home = {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          decorations = "none";
          dynamic_padding = true;
          padding = {
            x = 16;
            y = 16;
          };
          startup_mode = "Maximized";
        };

        scrolling.history = 10000;

        font = {
          normal.family = font;
          bold.family = font;
          italic.family = font;
          inherit size;
        };

        draw_bold_text_with_bright_colors = true;
        window.opacity = opacity;
      };
    };
  };
}
