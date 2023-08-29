{ writeShellApplication, teevik, lib }:

writeShellApplication {
  name = "asciiquarium-fullscreen";

  text = ''
    hyprctl dispatch exec '[fullscreen] wezterm --config window_padding="{left=0,right=0,top=0,bottom=0}" start ${lib.getExe teevik.asciiquarium}'
  '';
}
