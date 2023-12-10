{ writeShellApplication, teevik, lib }:

writeShellApplication {
  name = "asciiquarium-fullscreen";

  text = ''
    hyprctl dispatch exec '[fullscreen] kitty --override window_padding_width=0 ${lib.getExe teevik.asciiquarium}'
  '';
}
